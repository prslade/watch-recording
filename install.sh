#!/bin/sh
# Install the watch-recording script and Claude Code skill into your home directory.
set -eu
here=$(cd "$(dirname "$0")" && pwd)

mkdir -p "$HOME/.local/bin" "$HOME/.claude/skills/watch-recording"
install -m 755 "$here/watch-recording" "$HOME/.local/bin/watch-recording"
install -m 644 "$here/SKILL.md" "$HOME/.claude/skills/watch-recording/SKILL.md"

echo "Installed ~/.local/bin/watch-recording and ~/.claude/skills/watch-recording/SKILL.md"
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) echo "Add ~/.local/bin to your PATH so Claude can run watch-recording." ;;
esac
for tool in ffmpeg ffprobe whisper-cli; do
  command -v "$tool" >/dev/null 2>&1 || echo "Missing $tool: see Requirements in the README."
done
[ -f "$HOME/.local/share/whisper/ggml-small.en.bin" ] || echo "Missing the whisper model: see Requirements in the README."
