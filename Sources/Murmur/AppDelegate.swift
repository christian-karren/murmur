import AppKit
import AVFoundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: StatusBarController!
    private var hotkey: HotkeyManager!
    private var recorder: AudioRecorder!
    private var transcriber: Transcriber!
    private var paster: Paster!

    private var modelReady = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBar = StatusBarController()
        statusBar.onQuit = { NSApp.terminate(nil) }
        statusBar.setState(.loading("Loading model…"))

        recorder = AudioRecorder()
        transcriber = Transcriber()
        paster = Paster()

        hotkey = HotkeyManager()
        hotkey.onPress = { [weak self] in self?.toggleRecording() }
        hotkey.register()

        requestMicrophonePermission()
        promptForAccessibilityIfNeeded()

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.transcriber.loadModel()
                self.modelReady = true
                await MainActor.run {
                    self.statusBar.setState(.idle)
                }
            } catch {
                await MainActor.run {
                    self.statusBar.setState(.error("Model failed to load"))
                    self.showAlert(
                        title: "Murmur couldn't load the transcription model",
                        message: "Check your internet connection (first run downloads ~150MB) and restart.\n\n\(error.localizedDescription)"
                    )
                }
            }
        }
    }

    private func toggleRecording() {
        guard modelReady else {
            NSSound.beep()
            return
        }

        if recorder.isRecording {
            statusBar.setState(.transcribing)
            recorder.stop { [weak self] url in
                guard let self, let url else {
                    DispatchQueue.main.async { self?.statusBar.setState(.idle) }
                    return
                }
                Task {
                    let text = await self.transcriber.transcribe(audioURL: url)
                    try? FileManager.default.removeItem(at: url)
                    await MainActor.run {
                        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        if cleaned.isEmpty {
                            self.statusBar.setState(.idle)
                            NSSound.beep()
                        } else {
                            self.paster.paste(cleaned)
                            self.statusBar.setState(.idle)
                        }
                    }
                }
            }
        } else {
            do {
                try recorder.start()
                statusBar.setState(.recording)
            } catch {
                showAlert(
                    title: "Couldn't start recording",
                    message: error.localizedDescription
                )
            }
        }
    }

    private func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { _ in }
    }

    private func promptForAccessibilityIfNeeded() {
        let opts = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(opts)
        if !trusted {
            DispatchQueue.main.async {
                self.showAlert(
                    title: "Murmur needs Accessibility access",
                    message: "Grant access in System Settings → Privacy & Security → Accessibility, then quit and relaunch Murmur. Without it, the global hotkey and auto-paste won't work."
                )
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}
