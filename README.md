# splashaudio

A free, local macOS dictation menu-bar app. Press a global hotkey, speak, press it again — your words appear at the cursor. Built on [WhisperKit](https://github.com/argmaxinc/WhisperKit) so transcription runs on-device, with no API keys and no per-minute fees.

Designed to replace paid dictation tools for everyday use, including inside Claude Code.

Open source under the MIT license — fork it, change it, ship it.

## Requirements

- macOS 14 (Sonoma) or later, Apple Silicon recommended
- Xcode Command Line Tools (`xcode-select --install`)
- ~150 MB free disk space (the Whisper `base.en` model is downloaded on first launch)

## Build & install

```bash
git clone https://github.com/christian-karren/splashaudio.git
cd splashaudio
./build-app.sh
mv splashaudio.app /Applications/
open /Applications/splashaudio.app
```

The first build pulls WhisperKit from GitHub and compiles in release mode — a few minutes. Subsequent builds are fast.

## One-time permissions

macOS will prompt for some of these; others you must add manually.

1. **Microphone**: System Settings → Privacy & Security → Microphone → enable **splashaudio**.
2. **Accessibility** (required for the hotkey and auto-paste): System Settings → Privacy & Security → Accessibility → click `+` → add `/Applications/splashaudio.app` → toggle on.

The menu-bar icon flips from yellow to ready as soon as Accessibility is granted — no relaunch needed.

## Usage

- Press **⌘⇧;** to start recording. The menu bar icon turns red.
- Press **⌘⇧;** again to stop. splashaudio transcribes and pastes at your cursor.
- Works in any app — including Claude Code in Terminal/iTerm.

The first transcription after launch downloads the model (`base.en`, ~150 MB) to `~/Documents/huggingface/`. After that, transcriptions take roughly half a second for short utterances on Apple Silicon.

## How it works

1. **Global hotkey** is registered through Carbon's `RegisterEventHotKey`, so it fires regardless of which app is focused.
2. **Recording** writes 16 kHz mono PCM via `AVAudioRecorder` to a temp file.
3. **Transcription** runs locally via WhisperKit's Core ML pipeline (Apple Neural Engine when available).
4. **Paste** snapshots your clipboard, writes the transcribed text, sends a synthetic ⌘V via `CGEvent`, then restores your previous clipboard contents.

## Tweaking

- **Change the model**: edit `Sources/splashaudio/Transcriber.swift` and swap `openai_whisper-base.en` for e.g. `openai_whisper-small.en` (more accurate, slower) or `openai_whisper-tiny.en` (faster, less accurate). Browse all options at the [WhisperKit model list](https://huggingface.co/argmaxinc/whisperkit-coreml).
- **Change the hotkey**: edit the `modifiers` and `keyCode` in `Sources/splashaudio/HotkeyManager.swift`. Key codes come from `Carbon.HIToolbox` (e.g. `kVK_ANSI_D` for "D").

After any change: `./build-app.sh && cp -R splashaudio.app /Applications/`.

## Development run

You can iterate without the app bundle:

```bash
swift run
```

Note: when run this way, **Terminal** (or whichever shell host you launched from) needs Accessibility permission — not splashaudio — because the hotkey + paste events come from Terminal's process. For day-to-day use, prefer the `.app` build.

## Why not a paid dictation app?

This is a stripped-down clone. It only does what dictation needs: hotkey, transcribe, paste. No cloud, no subscription, no LLM cleanup pass. If you want raw speech-to-text that costs nothing per month, this is it.

## License

[MIT](LICENSE).
