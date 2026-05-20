import AppKit
import Carbon.HIToolbox

final class HotkeyManager {
    var onPress: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    func register() {
        let keyID = EventHotKeyID(signature: fourCharCode("MURM"), id: 1)
        // Cmd+Shift+; — Cmd+Option+Space is reserved by Spotlight on macOS and
        // gets intercepted by the OS before reaching our handler.
        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
        let keyCode: UInt32 = UInt32(kVK_ANSI_Semicolon)

        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            keyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        guard registerStatus == noErr else {
            NSLog("Murmur: failed to register hotkey (status \(registerStatus))")
            return
        }
        NSLog("Murmur: hotkey ⌘⇧; registered")

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData -> OSStatus in
                guard let userData else { return noErr }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                NSLog("Murmur: hotkey fired")
                DispatchQueue.main.async { manager.onPress?() }
                return noErr
            },
            1,
            &eventSpec,
            selfPtr,
            &handlerRef
        )
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }
}

private func fourCharCode(_ string: String) -> FourCharCode {
    var code: FourCharCode = 0
    for byte in string.utf8.prefix(4) {
        code = (code << 8) | FourCharCode(byte)
    }
    return code
}
