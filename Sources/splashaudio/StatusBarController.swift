import AppKit

enum AppState {
    case loading(String)
    case needsAccessibility
    case idle
    case recording
    case transcribing
    case error(String)
}

final class StatusBarController {
    var onQuit: (() -> Void)?
    var onOpenAccessibilitySettings: (() -> Void)?

    private let item: NSStatusItem
    private let menu = NSMenu()
    private let statusMenuItem = NSMenuItem(title: "Starting…", action: nil, keyEquivalent: "")
    private let accessibilityMenuItem = NSMenuItem(
        title: "Open Accessibility Settings…",
        action: #selector(handleOpenAccessibility),
        keyEquivalent: ""
    )

    init() {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        configureMenu()
        setState(.loading("Starting…"))
    }

    func setState(_ state: AppState) {
        DispatchQueue.main.async { [self] in
            guard let button = item.button else { return }
            button.contentTintColor = nil
            accessibilityMenuItem.isHidden = true

            switch state {
            case .loading(let label):
                button.image = symbol("hourglass")
                button.image?.isTemplate = true
                statusMenuItem.title = label
            case .needsAccessibility:
                button.image = symbol("exclamationmark.triangle.fill")
                button.image?.isTemplate = false
                button.contentTintColor = .systemYellow
                statusMenuItem.title = "Needs Accessibility permission"
                accessibilityMenuItem.isHidden = false
            case .idle:
                button.image = symbol("waveform")
                button.image?.isTemplate = true
                statusMenuItem.title = "Ready — ⌘⇧; to dictate"
            case .recording:
                button.image = symbol("mic.fill")
                button.image?.isTemplate = false
                button.contentTintColor = .systemRed
                statusMenuItem.title = "Recording — press ⌘⇧; to stop"
            case .transcribing:
                button.image = symbol("waveform.badge.magnifyingglass")
                button.image?.isTemplate = true
                statusMenuItem.title = "Transcribing…"
            case .error(let label):
                button.image = symbol("exclamationmark.triangle.fill")
                button.image?.isTemplate = false
                button.contentTintColor = .systemYellow
                statusMenuItem.title = label
            }
        }
    }

    private func configureMenu() {
        menu.addItem(statusMenuItem)
        menu.addItem(.separator())

        accessibilityMenuItem.target = self
        accessibilityMenuItem.isHidden = true
        menu.addItem(accessibilityMenuItem)

        let hotkeyHint = NSMenuItem(title: "Hotkey: ⌘⇧;", action: nil, keyEquivalent: "")
        hotkeyHint.isEnabled = false
        menu.addItem(hotkeyHint)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit splashaudio", action: #selector(handleQuit), keyEquivalent: "q")
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

    @objc private func handleOpenAccessibility() {
        onOpenAccessibilitySettings?()
    }
}
