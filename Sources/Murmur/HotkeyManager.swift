import AppKit
import Carbon.HIToolbox

final class HotkeyManager {
    var onPress: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    func register() {
        let keyID = EventHotKeyID(signature: fourCharCode("MURM"), id: 1)
        let modifiers: UInt32 = UInt32(cmdKey | optionKey)
        let keyCode: UInt32 = UInt32(kVK_Space)

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
