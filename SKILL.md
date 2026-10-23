---
name: watch-recording
description: Watch and listen to a narrated screen recording (.mov/.mp4) the user made, then respond to or act on what they said. Use when they say "watch this", "watch the latest recording", "I recorded a walkthrough", point at ~/Desktop/screen-recordings-for-agents, or paste a path to a screen recording.
---

# Watch a narrated screen recording

The user records their screen while narrating and annotating. A speech model turns the audio into a transcript and ffmpeg pulls frames every ~2s, at every spoken segment, and at every pointing word ("this", "here", "these", "those", "there"), so what they say can be matched to what was on screen. The screen often carries context they never say aloud (a selected filter, a label, drawn markup), so watching is half the job.

## Steps

1. Run `watch-recording`. With no argument it picks the newest video in `~/Desktop/screen-recordings-for-agents` (or `$WATCH_INBOX`), which is the right default. If they gave a path, pass it as-is: the script unescapes `\ ` and restores the narrow no-break space macOS puts before AM/PM, which pasted paths lose. A path under `.../TemporaryItems/NSIRD_screencaptureui_*` is a screen-capture temp file that cannot be listed and may vanish when the thumbnail is dismissed, so copy it into the inbox first (Python `shutil.copy2`; the shell also mangles that space) and then run `watch-recording`.
2. Read the printed `report.md`. It is the transcript in order, with frame paths under each segment. Pointing words are tagged `[pointing: "this"]`; the header says how many frames there are.
3. Default to reading every frame in the report, in order, before answering, about eight `Read` calls per message. This is a default, not a ceiling: being on the same page matters more than saving tokens, and the screen carries context the user never says aloud. Note the cursor, drawn markup, what is selected or checked, and what changes between frames. Then use judgment on top of it: if the header lists skipped or thinned frames and the narration leaves a gap there, extract them; if something is too small to read, zoom in (see "Pulling more"); if a recording is very long, say what you are sampling and why rather than skimming silently.
4. Usually open the reply with a readback: what they said, and what was on screen at the "this"/"here" moments that matter, so they can correct you early. Scale it to the recording: a 20-second check-in needs a line, a long walkthrough needs more. Flag any place where the narration and the screen disagree, or where the transcript looks garbled. Then do what the narration asks. If it ends with a question or an ask, answer it.
5. Anything outward-facing or hard to reverse (posting, pushing, editing a shared file) still gets confirmed first, even when the recording asks for it.

## Limits to say out loud when they matter

- Frames are samples (every ~2s plus each segment and pointing word), so fast cursor movement between them is lost. If a reference is ambiguous, say which timestamp and ask rather than guessing.
- The transcript is a draft, not ground truth. Either engine can garble or drop a phrase. When a phrase reads oddly, look at the frames around it and say what you think was said.
- `WATCH_MAX_FRAMES` (default 150) is a runaway guard, not a token budget, and the report header says when it dropped anything. A frame costs roughly 2k tokens, so a 2-minute recording is about 130k; that is not a reason to skip frames.
- Frames in the report are downscaled to 1600px wide from the source (usually 4096x2304), and the screen-change check is coarse, so small text and small changes can be lost.

## Pulling more

The report header gives the `Source:` path. When the report is not enough, extract what you need yourself:

```bash
# one frame at full resolution, cropped (crop=w:h:x:y in source pixels)
ffmpeg -v error -ss 74.3 -i "<Source>" -frames:v 1 -vf "crop=1200:700:200:300" /tmp/zoom.png
# a dense window: 4 frames per second from 1:04 for 6 seconds
ffmpeg -v error -ss 64 -t 6 -i "<Source>" -vf "fps=4,scale=1600:-1" /tmp/win_%02d.jpg
```

Say what you pulled and why. Re-run with `WATCH_MAX_FRAMES` higher or `WATCH_ENGINE=parakeet` if that is what the recording needs.
- Narration is the source of intent; the screen is the referent. If they disagree, flag it.
- Tip for the user: pause the cursor on the thing for about a second while saying "this". That is the moment a frame lands on.

## Setup

See the README for install steps. The script is `watch-recording` on `PATH` (`~/.local/bin`). Output cache is `~/.cache/watch-recording/<name>/`. Two speech engines, chosen with `WATCH_ENGINE` (default `whisper`):

- `whisper`: `whisper-cli` (brew `whisper-cpp`), model at `~/.local/share/whisper/ggml-small.en.bin`. Set `WATCH_VOCAB` to a comma-separated list of names to prime it toward words it would otherwise mishear.
- `parakeet`: NVIDIA Parakeet TDT 0.6b v3 through `parakeet-mlx`, in its own venv at `~/.local/share/parakeet-venv` (delete the folder to remove it). No vocabulary hints, but it got proper nouns right unprompted in testing.
