import AppKit
import Carbon
import Carbon.HIToolbox

enum HotkeyAction: Int {
    case area = 1
    case window = 2
    case fullscreen = 3
}

final class HotkeyManager {
    var onHotkey: ((HotkeyAction) -> Void)?

    private var hotkeyRefs: [EventHotKeyRef?] = []
    private var eventHandler: EventHandlerRef?

    func registerAll(area: HotkeyBinding, window: HotkeyBinding, fullscreen: HotkeyBinding) {
        unregisterAll()
        installHandlerIfNeeded()
        register(binding: area, action: .area)
        register(binding: window, action: .window)
        register(binding: fullscreen, action: .fullscreen)
    }

    func unregisterAll() {
        for ref in hotkeyRefs {
            if let ref {
                UnregisterEventHotKey(ref)
            }
        }
        hotkeyRefs.removeAll()
    }

    private func installHandlerIfNeeded() {
        guard eventHandler == nil else { return }
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                var hotKeyID = EventHotKeyID()
                let err = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                if err == noErr, let action = HotkeyAction(rawValue: Int(hotKeyID.id)) {
                    DispatchQueue.main.async {
                        manager.onHotkey?(action)
                    }
                }
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
        if status != noErr {
            NSLog("MacShot: failed to install hotkey handler (%d)", status)
        }
    }

    private func register(binding: HotkeyBinding, action: HotkeyAction) {
        let hotKeyID = EventHotKeyID(signature: OSType(0x4D534854), id: UInt32(action.rawValue)) // 'MSHT'
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            binding.keyCode,
            binding.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        if status != noErr {
            NSLog("MacShot: failed to register hotkey %d (%d)", action.rawValue, status)
        }
        hotkeyRefs.append(ref)
    }

    deinit {
        unregisterAll()
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}
