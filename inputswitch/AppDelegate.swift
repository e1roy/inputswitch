import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let inputSourceMonitor = InputSourceMonitor()
    let hotKeyManager = HotKeyManager()
    var hudController: HUDWindowController!
    let colorManager = InputSourceColorManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerDefaults()

        hudController = HUDWindowController(colorManager: colorManager)

        // Record all currently known input sources
        for name in inputSourceMonitor.allKeyboardInputSourceNames() {
            colorManager.recordInputSource(name)
        }

        // Input source change callback
        inputSourceMonitor.onInputSourceChanged = { [weak self] name, iconURL in
            guard let self = self else { return }
            self.colorManager.recordInputSource(name)
            self.hudController.showHUD(name: name, iconURL: iconURL)
        }

        // Enabled sources changed callback
        inputSourceMonitor.onEnabledSourcesChanged = { [weak self] in
            guard let self = self else { return }
            // Re-record sources so color manager stays current
            for name in self.inputSourceMonitor.allKeyboardInputSourceNames() {
                self.colorManager.recordInputSource(name)
            }
        }

        // Hot key show HUD callback (Fn double-tap)
        hotKeyManager.onShowHUD = { [weak self] in
            guard let self = self else { return }
            if let name = self.inputSourceMonitor.currentInputSourceName() {
                let iconURL = self.inputSourceMonitor.currentInputSourceIconURL()
                self.hudController.showHUD(name: name, iconURL: iconURL)
            }
        }

        // Start monitoring
        inputSourceMonitor.startMonitoring()
        hotKeyManager.startListening()

        // Listen for screen parameter changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        inputSourceMonitor.stopMonitoring()
        hotKeyManager.stopListening()
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func screenParametersChanged() {
        // No action needed; HUD size is computed per-show now.
    }

    private func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            DefaultsKey.hotKeySwitchInputSource: SwitchHotKey.rightCommand.rawValue,
            DefaultsKey.hudDisplayDuration: HUDConstants.defaultDisplayDuration,
        ])
    }
}
