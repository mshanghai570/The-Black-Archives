import AVFAudio

public final class SoundManager {
    public static let shared = SoundManager()
    private var audioPlayer: AVAudioPlayer?
    private var isEnabled: Bool = true

    private init() {}

    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    public func playSound(named name: String = "click", type: String = "mp3") {
        guard isEnabled else { return }
        
        DispatchQueue.global(qos: .userInteractive).async {
            guard let url = Bundle.main.url(forResource: name, withExtension: type) else {
                print("Sound file not found: \(name).\(type)")
                return
            }
            
            do {
                self.audioPlayer = try AVAudioPlayer(contentsOf: url)
                self.audioPlayer?.prepareToPlay()
                self.audioPlayer?.play()
            } catch {
                print("Failed to play sound: \(error.localizedDescription)")
            }
        }
    }

    public func playClick() {
        playSound(named: "click")
    }

    public func playSuccess() {
        playSound(named: "success")
    }

    public func playGenerate() {
        playSound(named: "generate")
    }

    public func playError() {
        playSound(named: "error")
    }
}
