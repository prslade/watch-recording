# watch-recording

A Claude Code skill that watches a narrated screen recording. You record your screen while talking (⌘⇧5 on macOS), and Claude gets a transcript with time-aligned frames, so "this" and "here" resolve to what was on screen.

## How it works

`watch-recording` transcribes the audio, then pulls frames:

- one every 2 seconds, skipping any screen that is unchanged from the last frame kept
- one in the middle of every spoken segment
- one at every pointing word ("this", "here", "these", "those", "there")

It writes `~/.cache/watch-recording/<name>/report.md`, the transcript in order with a frame path under each segment. `SKILL.md` tells Claude to read every frame, say back what it saw, then act on what you asked.

## Requirements

macOS, Python 3, and:

```sh
brew install ffmpeg whisper-cpp
mkdir -p ~/.local/share/whisper
curl -L -o ~/.local/share/whisper/ggml-small.en.bin \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-small.en.bin
```

Optional second engine, NVIDIA Parakeet on Apple silicon (`WATCH_ENGINE=parakeet`):

```sh
python3 -m venv ~/.local/share/parakeet-venv
~/.local/share/parakeet-venv/bin/pip install parakeet-mlx
```

## Install

```sh
./install.sh
```

This copies `watch-recording` to `~/.local/bin` and `SKILL.md` to `~/.claude/skills/watch-recording/`. Make sure `~/.local/bin` is on your `PATH`.

## Use

Save a recording to `~/Desktop/screen-recordings-for-agents`, then tell Claude "watch the latest recording". Or paste a path. You can also run it directly:

```sh
watch-recording                  # newest video in the inbox
watch-recording path/to/rec.mov
```

Tip: pause the cursor on the thing for about a second while saying "this". That is the moment a frame lands on.

## Settings

| Variable | Default | Effect |
| --- | --- | --- |
| `WATCH_ENGINE` | `whisper` | `whisper` or `parakeet` |
| `WATCH_MAX_FRAMES` | `150` | Cap on frames per recording. Frames at segments and pointing words always stay. |
| `WATCH_INBOX` | `~/Desktop/screen-recordings-for-agents` | Folder searched when no path is given |
| `WATCH_VOCAB` | empty | Comma-separated names to prime whisper toward (parakeet has no hints) |

Each frame costs Claude roughly 2k tokens, so a 2-minute recording is about 130k.
