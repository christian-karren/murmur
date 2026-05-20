import AppKit
import AVFoundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBar: StatusBarController!
    private var hotkey: HotkeyManager!
    private var recorder: AudioRecorder!
    private var transcriber: Transcriber!
    private var paster: Paster!

    private var modelReady = false
    private var accessibilityGranted = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBar = StatusBarController()
        statusBar.onQuit = { NSApp.terminate(nil) }
        statusBar.onOpenAccessibilitySettings = { Self.openAccessibilitySettings() }

        recorder = AudioRecorder()
        transcriber = Transcriber()
        paster = Paster()

        hotkey = HotkeyManager()
        hotkey.onPress = { [weak self] in self?.toggleRecording() }
        hotkey.register()

        requestMicrophonePermission()
        checkAccessibility()
        refreshState()

        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.transcriber.loadModel()
                self.modelReady = true
                await MainActor.run { self.refreshState() }
            } catch {
                await MainActor.run {
                    self.statusBar.setState(.error("Model failed to load"))
                    NSLog("Murmur: model load failed: \(error)")
                }
            }
        }
    }

    private func refreshState() {
        if !accessibilityGranted {
            statusBar.setState(.needsAccessibility)
        } else if !modelReady {
            statusBar.setState(.loading("Loading model…"))
        } else {
            statusBar.setState(.idle)
        }
    }

    private func checkAccessibility() {
        let opts = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        accessibilityGranted = AXIsProcessTrustedWithOptions(opts)
        if !accessibilityGranted {
            // Re-poll every 2s so the icon updates as soon as the user grants it,
            // without blocking the main thread on a modal alert.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self else { return }
                let trusted = AXIsProcessTrusted()
                if trusted != self.accessibilityGranted {
                    self.accessibilityGranted = trusted
                    self.refreshState()
                }
                if !self.accessibilityGranted {
                    self.checkAccessibility()
                }
            }
        }
    }

    static func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
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
                NSLog("Murmur: couldn't start recording: \(error)")
                statusBar.setState(.error("Recording failed — check Microphone permission"))
                NSSound.beep()
            }
        }
    }

    private func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { _ in }
    }
}
