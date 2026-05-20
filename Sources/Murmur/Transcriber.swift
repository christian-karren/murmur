import Foundation
import WhisperKit

actor Transcriber {
    private var pipeline: WhisperKit?

    func loadModel() async throws {
        let config = WhisperKitConfig(
            model: "openai_whisper-base.en",
            verbose: false,
            logLevel: .error,
            load: true
        )
        pipeline = try await WhisperKit(config)
    }

    func transcribe(audioURL: URL) async -> String {
        guard let pipeline else { return "" }
        do {
            let results = try await pipeline.transcribe(audioPath: audioURL.path)
            return results
                .map(\.text)
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            NSLog("Murmur: transcription failed: \(error)")
            return ""
        }
    }
}
