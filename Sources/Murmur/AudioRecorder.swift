import AVFoundation

final class AudioRecorder: NSObject {
    private var recorder: AVAudioRecorder?

    var isRecording: Bool { recorder?.isRecording ?? false }

    func start() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("murmur-\(UUID().uuidString)")
            .appendingPathExtension("wav")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.delegate = self
        guard recorder.prepareToRecord(), recorder.record() else {
            throw NSError(
                domain: "Murmur.AudioRecorder",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Recorder refused to start. Check microphone permission in System Settings."]
            )
        }
        self.recorder = recorder
    }

    func stop(completion: @escaping (URL?) -> Void) {
        guard let recorder else {
            completion(nil)
            return
        }
        let url = recorder.url
        recorder.stop()
        self.recorder = nil
        completion(url)
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {}
