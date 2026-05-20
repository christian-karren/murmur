import AppKit

enum MurmurState {
    case loading(String)
    case idle
    case recording
    case transcribing
    case error(String)
}

final class StatusBarController {
    var onQuit: (() -> Void)?

    private let item: NSStatusItem
    private let menu = NSMenu()
    private let statusMenuItem = NSMenuItem(title: "Loading…", action: nil, keyEquivalent: "")

    init() {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configureMenu()
        setState(.loading("Starting…"))
    }

    func setState(_ state: MurmurState) {
        DispatchQueue.main.async { [self] in
            guard let button = item.button else { return }
            switch state {
            case .loading(let label):
                button.image = symbol("hourglass")
                button.image?.isTemplate = true
                statusMenuItem.title = label
            case .idle:
                button.image = symbol("waveform")
                button.image?.isTemplate = true
                statusMenuItem.title = "Ready — ⌘⌥Space to dictate"
            case .recording:
                button.image = symbol("mic.fill")
                button.image?.isTemplate = false
                button.contentTintColor = .systemRed
                statusMenuItem.title = "Recording — press ⌘⌥Space to stop"
                return
            case .transcribing:
                button.image = symbol("waveform.badge.magnifyingglass")
                button.image?.isTemplate = true
                statusMenuItem.title = "Transcribing…"
            case .error(let label):
                button.image = symbol("exclamationmark.triangle.fill")
                button.image?.isTemplate = false
                button.contentTintColor = .systemYellow
                statusMenuItem.title = label
                return
            }
            button.contentTintColor = nil
        }
    }

    private func configureMenu() {
        menu.addItem(statusMenuItem)
        menu.addItem(.separator())

        let hotkeyHint = NSMenuItem(title: "Hotkey: ⌘⌥Space", action: nil, keyEquivalent: "")
        hotkeyHint.isEnabled = false
        menu.addItem(hotkeyHint)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Murmur", action: #selector(handleQuit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        item.menu = menu
    }

    private func symbol(_ name: String) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: name)
    }

    @objc private func handleQuit() {
        onQuit?()
    }
}
