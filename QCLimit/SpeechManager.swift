import Foundation
import Speech
import AVFoundation

final class SpeechManager: ObservableObject {
    @Published var isListening = false
    @Published var status = "Chạm micro rồi đọc: “1914 cộng trừ 20”"

    /// Nhận câu nghe được, trả về true nếu điền được số.
    var onText: ((String) -> Bool)?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "vi-VN"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func toggle() { isListening ? stop() : start() }

    func start() {
        SFSpeechRecognizer.requestAuthorization { auth in
            DispatchQueue.main.async {
                guard auth == .authorized else {
                    self.status = "Chưa cấp quyền nhận diện giọng nói. Vào Cài đặt > QC Limit để bật."
                    return
                }
                AVAudioSession.sharedInstance().requestRecordPermission { ok in
                    DispatchQueue.main.async {
                        guard ok else {
                            self.status = "Chưa cấp quyền micro. Vào Cài đặt > QC Limit để bật."
                            return
                        }
                        self.begin()
                    }
                }
            }
        }
    }

    private func begin() {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            status = "Máy chưa dùng được nhận diện tiếng Việt lúc này."
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let req = SFSpeechAudioBufferRecognitionRequest()
            req.shouldReportPartialResults = true
            request = req

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buf, _ in
                req.append(buf)
            }
            engine.prepare()
            try engine.start()

            task = recognizer.recognitionTask(with: req) { [weak self] result, error in
                guard let self = self else { return }
                if let r = result {
                    let t = r.bestTranscription.formattedString
                    DispatchQueue.main.async {
                        let ok = self.onText?(t) ?? false
                        self.status = ok ? "Đã nghe: “\(t)”" : "Nghe: “\(t)” – chưa nhận rõ số, thử đọc lại."
                        if r.isFinal { self.stop() }
                    }
                }
                if error != nil { DispatchQueue.main.async { self.stop() } }
            }
            isListening = true
            status = "Đang nghe… đọc STD cộng trừ dung sai"
        } catch {
            status = "Không mở được micro: \(error.localizedDescription)"
            stop()
        }
    }

    func stop() {
        if engine.isRunning { engine.stop() }
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        request = nil
        isListening = false
    }
}
