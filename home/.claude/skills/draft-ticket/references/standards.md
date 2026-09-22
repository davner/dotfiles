# Ticket standards: the sourced part

Read this when a drafting judgment is actually contested: whether something is
one story or three, whether an acceptance criterion is real, whether the story
template belongs on this ticket at all. `SKILL.md` carries the rules; this
carries why they are the rules and where they come from, so a disagreement can
be settled against a source instead of against taste.

Everything below is attributed. Where the industry does not agree, that is said
rather than hidden, because a confident rule invented to fill a gap is how a
skill ships an opinion as a fact.

## INVEST

Bill Wake, 2003. The test a story passes before it enters a sprint.

| | | |
| --- | --- | --- |
| **I** | Independent | Stories do not overlap in concept, so they can be built and shipped in any order. |
| **N** | Negotiable | The card is not a contract. Details are co-created by whoever wants it and whoever builds it. |
| **V** | Valuable | Worth to the customer, not to the developers. Slice **vertically** through the layers. |
| **E** | Estimable | Not an exact number - just enough for someone to rank and schedule it. |
| **S** | Small | At most a few person-weeks. Agile Alliance's gloss: fits inside one iteration. |
| **T** | Testable | "I understand what I want well enough that I could write a test for it." |

Wake's companion for tasks is SMART: Specific, Measurable, Achievable,
Relevant, Time-boxed.

Sources: `xp123.com/invest-in-good-stories-and-smart-tasks/`,
`agilealliance.org/glossary/invest/`.

## The 3 Cs, and what a drafted ticket actually is

Ron Jeffries, 2001: a story is a **Card**, a **Conversation**, and a
**Confirmation**. The card is a token, not a spec; the conversation is where
the requirement is really made; the confirmation is the acceptance criteria.

This is the load-bearing fact for a drafting skill. **The skill only produces
the Card.** The Conversation it cannot hold, so the card has to carry enough
that its absence is survivable, and the Confirmation has to be written down
explicitly rather than left to be discussed. That is the whole reason this
skill pushes so hard on sourcing the "why" and on binary acceptance criteria.

Source: `agilealliance.org/glossary/three-cs/`.

## Where the industry disagrees: the story template

The only real split in the literature, and the skill has to hold a position.

| Position | Who | Claim |
| --- | --- | --- |
| Drop it when it reads badly | Cohn, Patton, Marcano, and Atlassian itself | Atlassian's own page, immediately after giving the template: "This structure is not required, but it is helpful for defining done. ... We encourage teams to define their own structure, and then to stick to it." Cohn: "Do not force everything into user story form"; technical work is "better treated as a technical backlog item, spike, chore, or task", and a story beginning "As a developer..." is a named smell. |
| Keep it uniform | The QUS academic framework (Lucassen et al., 2016) | Scores a story **down** for being non-**Uniform** with the rest of the set. |

**The skill's resolution, and it is a synthesis rather than a citation:**
uniform within a type, free across types. Every Feature takes the Connextra
sentence, every Bug takes the Mozilla field set, every Chore takes the FDD
shape. Nothing is bent into a template that does not fit it. This satisfies
QUS's Uniform within the set a reader is actually comparing, and satisfies
Cohn by never forcing a Chore into a user's voice.

One detail worth keeping right: the Connextra original said "I want **to do
something**". The industry mutated it to "I want **\[feature]**", which turns
the story back into feature documentation (Marcano,
`antonymarcano.com/blog/2016/08/how-the-industry-broke-the-connextra-template/`).

Cohn's replacement shape for technical and API work is the FDD feature:

```
[action] the [result] [by|for|of|to] a(n) [object]
```

"Generate a unique identifier for a transaction." "Merge the data for
duplicate transactions." Source:
`mountaingoatsoftware.com/agile/not-everything-needs-to-be-a-user-story-using-fdd-features`.

Non-functional requirements are the exception that keeps the story voice, and
for a good reason: "Must use existing orders database" loses its *why* within
months, where "As a user, I want the site to be available 99.999 percent of the
time I try to access it, so that I don't get frustrated and find another site"
does not.

## Acceptance criteria

Cohn calls them **conditions of satisfaction**, deliberately, because
"acceptance criteria" makes people think of testing: "details that help a
product owner and team confirm whether a story has been completed correctly."
They "are not meant to be a full test plan."

On how many, his exact answer, and the reason the skill refuses to name a
number: **"As many as are useful and no more. If the list is long, the story
may be too large."** Every "3 to 7" and "split above 10" figure in circulation
traces to vendor blogs, not to a primary source.

On what they are not: a Definition of Done is "an agreed-upon set of things
that must be true before **any** product backlog item is considered complete",
while conditions of satisfaction "are specific to a given product backlog
item". Restating DoD items as AC is therefore always wrong - it is noise that
buries the specific ones.

Sources: `mountaingoatsoftware.com/agile/user-stories/acceptance-criteria`, and
the DoD-vs-CoS article on the same site.

### Given / When / Then

Fowler, 2013, crediting Dan North and Chris Matts: **Given** is the state of
the world before the behavior, **When** is the behavior being specified,
**Then** is the change expected because of it. He frames it as a reformulation
of the Four-Phase Test (Setup / Exercise / Verify / Teardown), with teardown
dropped because it adds nothing to communication.

Cucumber's rules that matter when drafting:

- Steps avoid implementation detail. The test: **"Will this wording need to
  change if the implementation does?"** If yes, it is at the wrong altitude.
- `Then` asserts **observable output**. "Resist verifying database changes
  users cannot see."
- Conjunction steps are an anti-pattern: "Given I have shades and a brand new
  Mustang" makes a step too specialised to reuse. Split it.

Sources: `martinfowler.com/bliki/GivenWhenThen.html`,
`cucumber.io/docs/gherkin/reference/`, `cucumber.io/docs/bdd/better-gherkin/`,
`cucumber.io/docs/guides/anti-patterns/`.

## Bug reports

The field set below is the one that appears in at least two of the three
canonical sources, which is why the skill's bug template is shaped this way:
**Summary, Environment/build, Steps to reproduce, Expected, Actual, Evidence,
Severity, Priority, Regression info, Frequency.** ("Workaround" as a named
field is an inference, not a convergence - Azure only implies it through its
severity definitions.)

Mozilla's bug-writing guidelines are the oldest and still the sharpest:

- **"Steps to reproduce are the most important part of any bug report."**
- Summary **under 60 characters**, describing the problem and **not proposing a
  solution**. Good: "Cancelling a File Copy dialog crashes File Manager."
  "Down-arrow scrolling doesn't work in `<textarea>` styled with
  overflow:hidden." Bad: "Software crashes." "Browser should work with my web
  site."
- State whether it reproduces consistently, occasionally, or not at all.
- Expected and Actual are separate, and must "distinguish facts from
  speculation". Never "It doesn't work".

Source: `bugzilla.mozilla.org/page.cgi?id=bug-writing.html`.

### Severity is not priority

Microsoft's Azure Boards definitions, and the reason the skill insists on both:

| Severity | Meaning |
| --- | --- |
| 1 Critical | Terminates a component or the whole system, or corrupts data extensively. **No acceptable alternative exists.** |
| 2 High | The same damage, but an acceptable alternative method exists. |
| 3 Medium | Produces incorrect, incomplete, or inconsistent results. |
| 4 Low | Minor or cosmetic, with acceptable workarounds. |

Priority runs on its own axis: 1 must be resolved before ship and needs
attention now; 2 must be resolved before ship but not now; 3 is optional,
based on resources, time, and risk.

Their canonical worked example is the whole point: a rare UI path that crashes
the app is **Severity 2, Priority 3**. Collapse the two and that ticket is
either panic or invisible, and both are wrong.

Also from the same doc, and the source of the skill's rule: **"Don't reopen
closed bugs for regressions. Instead, open a new bug and link it to the
original with a Related link."**

Source: `learn.microsoft.com/en-us/azure/devops/boards/backlogs/manage-bugs`.

## Epics and splitting

Atlassian on epics: "a large body of work that can be broken down into a
number of smaller stories", "almost always delivered over a set of sprints",
with **flexible scope** that moves with customer feedback, and it "should give
the development team everything they need to be successful". A story, by
contrast, is sized to finish inside one sprint.

Worth knowing when drafting: no primary source gives a **field list** for an
epic description. Atlassian gives only that one sentence plus advice about
reporting and storytelling. The skill's epic template is therefore house
convention, not industry practice, and can be changed freely.

Source: `atlassian.com/agile/project-management/epics`.

### Vertical slice

"A work item that delivers a valuable change in system behavior such that
you'll probably have to touch multiple architectural layers to implement the
change." SAFe says the same in a clause: a story is "a small, vertical slice of
intended system behavior". This is Wake's **V** restated, and it is what rules
out splitting by layer.

### SPIDR (Cohn) - five cuts that produce shippable slices

| | Cut | Example |
| --- | --- | --- |
| **S** | Spike | Research first, then split with the knowledge you bought. |
| **P** | Path | One path through the story per iteration. |
| **I** | Interface | A simpler interface first, or one browser or device first. |
| **D** | Data | A subset of the data first - MP4 before the other 15 formats. |
| **R** | Rules | Relax a business rule initially - upload video before copyright detection. |

You do not apply all five. Find the one that produces a slice you would
actually ship, and avoid task-based or layer-based splits.

Humanizing Work's guide (Richard Lawrence) gives nine patterns in a flowchart:
workflow steps, operations (CRUD), business rule variations, variations in
data, data entry methods, major effort, simple/complex, defer performance,
break out a spike. (The "20 ways to split a user story" framing circulating in
secondary posts is not what Lawrence's own current guide says - don't cite it.)

Sources: `mountaingoatsoftware.com/blog/five-simple-but-powerful-ways-to-split-user-stories`,
`humanizingwork.com/the-humanizing-work-guide-to-splitting-user-stories/`.

## Definition of Done, and the thing that is not one

**DoD is normative.** The 2020 Scrum Guide: "a formal description of the state
of the Increment when it meets the quality measures required for the product",
and an item that does not meet it "cannot be released or even presented at the
Sprint Review". Owned by the Scrum Team; an organisation-wide DoD is a floor,
not a ceiling.

**Definition of Ready is not.** The term appears nowhere in the 2020 Scrum
Guide, and Scrum.org hosts active criticism of it - that a mandated DoR reduces
a team's ability to self-manage, introduces wait states, and can block the
highest-value item for being "not ready". Section 7 of `SKILL.md` is a quality
bar for this skill's own output; do not present it to anyone as a Definition of
Ready.

Source: `scrumguides.org/scrum-guide.html`.

## The anti-pattern list with actual evidence behind it

The Quality User Story framework (Lucassen, Dalpiaz, van der Werf &
Brinkkemper, *Requirements Engineering* 21(3), 2016) is the only anti-pattern
list in the literature with defined criteria, real defective examples, and a
measured base rate. Across **1,023 stories from 18 organisations, 56% had at
least one defect.** Assume a first draft is in that 56% and check it.

| Criterion | The defect it catches |
| --- | --- |
| Well-formed | Missing role or means. Worst observed case: a story whose entire text was "Server configuration". |
| Atomic | Two features in one sentence, joined by "and thereby". |
| Minimal | Implementation notes glued into the story sentence. The fix is to move them to the description, not to delete them. |
| Conceptually sound | The "so that" is a hidden dependency rather than a rationale. "I want to open the interactive map, so that I can see the location of landmarks" is two stories. |
| Problem-oriented | The story hints at the solution: "Add save button on top right never grayed out". |
| Unambiguous | Terms with multiple readings. "I am able to edit the content that I added" - what is content? |
| Conflict-free | Contradicts another story in the set. |
| Full sentence | Not a sentence. |
| Estimable | Too coarse to plan. "I want to see my route list for next/future days" - unclear what "see my route list" implies. |
| Unique | A duplicate of another story. |
| Uniform | Deviates from the template its neighbours use. See the disagreement above for how the skill scopes this. |
| Independent | Carries an inherent dependency on another story. |
| Complete | The set leaves steps missing. |

Source: `webspace.science.uu.nl/~dalpi001/papers/luca-dalp-werf-brin-16-rej.pdf`.

## Shortcut, as the API actually defines it

Verified from `developer.shortcut.com/api/rest/v3/shortcut.swagger.json`
(API 3.0) and Shortcut's own help pages. These are the facts that change how a
description must be written, versus Jira.

| Fact | Consequence |
| --- | --- |
| `story_type` is exactly `["feature", "chore", "bug"]` | Three values carry almost no information compared to Jira's configurable issue types. The description has to state the nature of the work. |
| **There is no Spike type.** Research is a Chore. | Shortcut's own test is "is this going to change the product?", which is easier to answer than "does this provide business value?" Research does not change the product, so: Chore. |
| **There is no Severity field, and no built-in Priority.** Story carries `custom_fields` only. | Severity always goes in the description prose. A Priority in the sidebar is a workspace custom field, so never assume another workspace has one. |
| `Story.name` 1-512 chars; `Epic.name` 1-256; both descriptions max 100,000 | The limits are far above anything worth writing. Style caps the title, not the API. |
| `estimate` is a nullable integer | Non-integer scales are impossible. Null means unestimated, which is a legitimate state. Shortcut deliberately holds no opinion on whether bugs get estimated. |
| `story_links` carries blocks / blocked by / duplicates, and renders as a dependency chart on Epic and Iteration pages | Dependencies go in links, never in prose. Prose dependencies do not appear on the chart. |
| Labels attach to both Stories and Epics | Cross-cutting concerns are labels. This is why a title prefix is wasted width. |
| Epic is a first-class object with its own states and `objective_ids` | The epic description is read on its own page, often by people who will never open a story. Write it for that reader. |
| `WorkflowState.type` is Unstarted / Started / Finished, but `EpicState.type` is Unstarted / Started / **Done** | Only matters if something ever reads state programmatically. Noted because the asymmetry is surprising. |
| Iterations are orthogonal to Epics - a story has at most one `epic_id` and one `iteration_id` | An epic is not a sprint. Do not scope one as though it were. |
| Objectives are the top level, and **Epics** link to them, not stories | The why-chain runs story to epic to objective. A story that cannot trace upward is a sign the epic is missing. |

Shortcut also has native **Story Templates** (Settings > Story Templates),
which pre-fill title, type, description, tasks, team, epic, owners, custom
fields, labels, due date, and attachments. They cover the static scaffolding
this skill writes out each time. If the team adopts one, this skill's job
shrinks to the thinking part: what actually goes in the blanks.

## Jira, in one table

| Shortcut | Jira |
| --- | --- |
| Story type Feature | Story |
| Story type Bug | Bug |
| Story type Chore | Task |
| Epic | Epic |
| Estimate | Story Points |
| Iteration | Sprint |
| Labels | Labels / Components |
| Story links | Issue links |

Jira's summary field caps at 255 characters. Its description is ADF rather than
markdown, so paste into the editor and let it convert rather than expecting
raw markdown to survive.

## Known gaps in the above

Stated so nobody treats a hole as settled:

- No primary source gives a number for acceptance criteria per story. Cohn's
  "as many as are useful and no more" is the ceiling of what is actually
  supported.
- No primary source gives a field list for an epic description.
- Whether Shortcut renders markdown in **descriptions** is not stated in its
  help pages (comments are). The Create Story form's own toolbar - headings,
  bold, italic, code, link, checklist, ordered and unordered lists, and a
  Write/Preview tab pair - is the evidence this skill relies on.
- Jira's 255-character summary limit comes from an Atlassian community thread,
  not a documentation page.
- No Google-published guidance on ticket or bug-report authoring exists to
  compare against Mozilla's and Microsoft's. Their public engineering guides
  cover code review, not issue writing.
