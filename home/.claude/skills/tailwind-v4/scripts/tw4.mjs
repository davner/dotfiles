#!/usr/bin/env node
// Answers "does this class exist and what does it compile to" against the
// tailwindcss the project actually resolves, not against a documented version.
// Tailwind ships no CLI for this: the compiler is reachable only through the
// Node API, so a script is the only way to ask.
import fs from 'node:fs'
import path from 'node:path'
import { createRequire } from 'node:module'
import { pathToFileURL } from 'node:url'

const [cmd, ...rest] = process.argv.slice(2)

const args = []
const opts = {}
for (let i = 0; i < rest.length; i++) {
  if (rest[i] === '--css') opts.css = rest[++i]
  else if (rest[i] === '--cwd') opts.cwd = rest[++i]
  else args.push(rest[i])
}

const cwd = path.resolve(opts.cwd || process.cwd())

function findUp(name, from) {
  let dir = from
  for (;;) {
    const p = path.join(dir, 'node_modules', name)
    if (fs.existsSync(p)) return p
    const parent = path.dirname(dir)
    if (parent === dir) return null
    dir = parent
  }
}

const twDir = findUp('tailwindcss', cwd)
if (!twDir) {
  console.error(`no tailwindcss resolved from ${cwd}`)
  console.error('Run this from inside the project, or pass --cwd <project>.')
  process.exit(2)
}

const pkg = JSON.parse(fs.readFileSync(path.join(twDir, 'package.json'), 'utf8'))
const major = parseInt(pkg.version, 10)

function integrations() {
  const found = {}
  for (const n of [
    '@tailwindcss/vite', '@tailwindcss/postcss', '@tailwindcss/cli',
    '@tailwindcss/webpack', '@tailwindcss/typography', '@tailwindcss/forms',
    '@tailwindcss/aspect-ratio', '@tailwindcss/container-queries',
  ]) {
    const d = findUp(n, cwd)
    if (d) {
      try { found[n] = JSON.parse(fs.readFileSync(path.join(d, 'package.json'), 'utf8')).version }
      catch { found[n] = 'present' }
    }
  }
  return found
}

// A JS config only applies in v4 when a stylesheet names it with @config.
function legacyConfigs() {
  const names = ['tailwind.config.js', 'tailwind.config.cjs', 'tailwind.config.mjs', 'tailwind.config.ts']
  const hits = []
  let dir = cwd
  for (let depth = 0; depth < 4; depth++) {
    for (const n of names) {
      const p = path.join(dir, n)
      if (fs.existsSync(p)) hits.push(p)
    }
    const parent = path.dirname(dir)
    if (parent === dir) break
    dir = parent
  }
  return hits
}

function guessEntryCss() {
  if (opts.css) return path.resolve(cwd, opts.css)
  const candidates = [
    'src/app.css', 'src/index.css', 'src/styles.css', 'src/main.css',
    'src/styles/globals.css', 'src/app/globals.css', 'app/globals.css',
    'styles/globals.css', 'app.css', 'index.css', 'assets/css/app.css',
    'resources/css/app.css', 'src/assets/main.css', 'src/style.css',
  ]
  for (const c of candidates) {
    const p = path.join(cwd, c)
    if (fs.existsSync(p) && /@import\s+["']tailwindcss/.test(fs.readFileSync(p, 'utf8'))) return p
  }
  return null
}

function reportVersion() {
  const entry = guessEntryCss()
  const legacy = legacyConfigs()
  console.log(JSON.stringify({
    installed: pkg.version,
    resolvedFrom: twDir,
    appliesToThisSkill: major === 4,
    integrations: integrations(),
    entryCss: entry ? path.relative(cwd, entry) : null,
    legacyJsConfig: legacy.map((p) => path.relative(cwd, p)),
  }, null, 2))
  if (major !== 4) {
    console.log(`\n!! tailwindcss ${pkg.version} is not v4. This skill does not apply.`)
  }
  if (legacy.length && entry) {
    const css = fs.readFileSync(entry, 'utf8')
    if (!/@config\s/.test(css)) {
      console.log(`\n!! ${path.relative(cwd, legacy[0])} exists but ${path.relative(cwd, entry)} has no @config.`)
      console.log('   v4 does not auto-load a JS config. Everything in it is being ignored.')
    }
  }
}

async function designSystem() {
  if (major !== 4) {
    console.error(`tailwindcss ${pkg.version} is not v4; the v4 compiler API is unavailable.`)
    process.exit(2)
  }
  const req = createRequire(pathToFileURL(path.join(twDir, 'package.json')))
  // require.resolve picks the CJS build, whose named exports arrive under
  // .default once imported. Prefer the ESM entry and fall back either way.
  const esm = pkg.exports?.['.']?.import
  const entryPath = esm ? path.join(twDir, esm) : req.resolve('tailwindcss')
  const raw = await import(pathToFileURL(entryPath).href)
  const mod = typeof raw.__unstable__loadDesignSystem === 'function' ? raw : (raw.default ?? raw)
  if (typeof mod.__unstable__loadDesignSystem !== 'function') {
    console.error(`tailwindcss ${pkg.version} does not expose __unstable__loadDesignSystem.`)
    console.error('This skill\'s check/css/variants/search/theme commands need it; version still works.')
    process.exit(2)
  }
  const entry = guessEntryCss()
  const css = entry ? fs.readFileSync(entry, 'utf8') : '@import "tailwindcss";'
  const base = entry ? path.dirname(entry) : cwd

  const built = (opts) => mod.__unstable__loadDesignSystem(css, opts)
  return {
    entry,
    ds: await buildOrExplain(built, entry, {
      base,
      // An import this script cannot resolve must degrade to a warning, not a
      // stack trace: the answer for built-in utilities is still correct without
      // it, and the warning says which custom values are missing from it.
      loadStylesheet: async (id, from) => {
        let p
        if (id === 'tailwindcss') p = req.resolve('tailwindcss/index.css')
        else if (id.startsWith('tailwindcss/')) p = req.resolve(id)
        else if (id.startsWith('.') || path.isAbsolute(id)) p = path.resolve(from, id)
        else {
          try { p = req.resolve(id) } catch { p = path.resolve(from, id) }
        }
        try {
          return { path: p, base: path.dirname(p), content: fs.readFileSync(p, 'utf8') }
        } catch {
          console.error(`warning: could not read @import "${id}" (looked at ${p}); continuing without it`)
          return { path: p, base: path.dirname(p), content: '' }
        }
      },
      // A @plugin or @config the skill cannot load must not abort the whole
      // lookup; the answer for built-in utilities is still correct without it.
      loadModule: async (id, from) => {
        try {
          const p = id.startsWith('.') ? path.resolve(from, id) : req.resolve(id)
          const m = await import(pathToFileURL(p).href)
          return { path: p, base: path.dirname(p), module: m.default ?? m }
        } catch {
          return { path: id, base: from, module: () => {} }
        }
      },
    }),
  }
}

// Any failure below is a problem with the project's stylesheet, and the useful
// report names it and suggests --css rather than showing this script's frames.
async function buildOrExplain(build, entry, opts) {
  try {
    return await build(opts)
  } catch (err) {
    console.error(`could not compile ${entry ? entry : 'the default stylesheet'}: ${err?.message ?? err}`)
    if (entry) console.error('Pass --css <file> to use a different entry stylesheet.')
    process.exit(2)
  }
}

function fmt(css) {
  return css.replace(/@property[\s\S]*$/, '').replace(/\s+/g, ' ').trim()
}

switch (cmd) {
  case 'version':
  case undefined:
    reportVersion()
    break

  case 'check': {
    if (!args.length) { console.error('usage: tw4.mjs check <class> [class...]'); process.exit(1) }
    const { ds, entry } = await designSystem()
    if (entry) console.log(`# resolved against ${path.relative(cwd, entry)}\n`)
    const out = ds.candidatesToCss(args)
    let bad = 0
    args.forEach((c, i) => {
      if (out[i] === null) { bad++; console.log(`✗ ${c}  NOT A UTILITY`) }
      else console.log(`✓ ${c}  ${fmt(out[i]).slice(0, 120)}`)
    })
    process.exit(bad ? 1 : 0)
    break
  }

  case 'css': {
    if (!args.length) { console.error('usage: tw4.mjs css <class> [class...]'); process.exit(1) }
    const { ds } = await designSystem()
    const out = ds.candidatesToCss(args)
    args.forEach((c, i) => {
      console.log(`/* ${c} */`)
      console.log(out[i] === null ? '  NOT A UTILITY' : out[i])
    })
    break
  }

  case 'variants': {
    const { ds } = await designSystem()
    const vs = ds.getVariants()
    for (const v of vs) {
      const vals = v.values?.length ? `  values: ${v.values.slice(0, 12).join(', ')}${v.values.length > 12 ? ', …' : ''}` : ''
      console.log(`${v.name.padEnd(22)}${v.isArbitrary ? '[arbitrary] ' : ''}${vals}`)
    }
    console.log(`\n${vs.length} variants`)
    break
  }

  case 'search': {
    if (!args.length) { console.error('usage: tw4.mjs search <substring>'); process.exit(1) }
    const { ds } = await designSystem()
    const names = ds.getClassList().map((c) => (Array.isArray(c) ? c[0] : c))
    const re = new RegExp(args[0])
    const hits = names.filter((n) => re.test(n))
    console.log(hits.slice(0, 200).join('\n'))
    console.log(`\n${hits.length} of ${names.length} classes match /${args[0]}/${hits.length > 200 ? ' (showing 200)' : ''}`)
    break
  }

  case 'theme': {
    const { ds } = await designSystem()
    const re = args[0] ? new RegExp(args[0]) : /./
    const entries = [...ds.theme.entries()].filter(([k]) => re.test(k))
    for (const [k, v] of entries) console.log(`${k}: ${v.value ?? v}`)
    console.log(`\n${entries.length} theme variables match`)
    break
  }

  default:
    console.error(`unknown command: ${cmd}

usage: node tw4.mjs <command> [--cwd <dir>] [--css <entry.css>]

  version              installed tailwindcss, integrations, entry CSS, stray JS config
  check <class...>     does each class exist here (exit 1 if any do not)
  css <class...>       the CSS each class compiles to
  variants             every variant this project can use
  search <regex>       find classes by pattern
  theme [regex]        resolved theme variables
`)
    process.exit(1)
}
