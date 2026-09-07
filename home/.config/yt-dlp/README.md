# yt-dlp

Three aliases defined in `config`, for getting audio and video off YouTube and
onto the phone. Everything lands under `~/Documents`, which is the
iCloud-synced folder, so the files appear in Files on iOS with no copy step.

| Command | Lands in | For |
| --- | --- | --- |
| `yt-dlp --vid URL` | `~/Documents/YouTube/Video` | CapCut. h264+aac mp4, capped at 1080p |
| `yt-dlp --aud URL` | `~/Documents/YouTube/Audio` | Full-length m4a, artwork embedded |
| `yt-dlp --tone RANGE URL` | `~/Documents/YouTube/Tones` | A trimmed clip, written as both `.m4a` and `.m4r` |

`--tone` takes the range first: `yt-dlp --tone 0:12-0:38 URL`. `-T` is the short
form. The folders are created on first use.

The cut is exact to the second, because the alias passes
`--force-keyframes-at-cuts`. Without it the range snaps to the nearest keyframe
and a 28s request can arrive as 31s, which iOS then refuses.

## Getting a tone onto the phone

iOS will not install a tone from the Files app, which is why `--tone` writes the
same audio twice. The two routes want different extensions:

| Route | Needs | Uses |
| --- | --- | --- |
| Finder device sync | The iPhone connected to this Mac | the `.m4r` |
| GarageBand on iOS | Import, then Share as Ringtone | the `.m4a` |

Length is capped by iOS: 30s for a text tone, 40s for a ringtone.
`tone-finish.sh` prints a warning when the result is past 30s rather than
letting it fail silently on the phone.

CapCut and ordinary audio playback are unaffected. Those import from Files
normally.

## Notes

`yt-dlp --help` lists the aliases too, near the bottom, but only as the raw
option strings they expand to.

Editing `config` here changes behavior immediately. It is symlinked into
`~/.config/yt-dlp`, so there is no rebuild in between.

If YouTube starts refusing extraction, the documented first thing to try is
passing browser cookies, e.g. `--cookies-from-browser safari`.
