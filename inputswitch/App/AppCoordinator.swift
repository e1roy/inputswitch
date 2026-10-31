import AppKit

/// Composition root: owns every service and wires their events together.
///
/// ```
/// InputSourceService ──changed──▶ HUDController
/// AppSettings / HUDAppearanceStore ──read by──▶ HUDController
/// ```
final class AppCoordinator {
    let settings: AppSettings
    let appearance: HUDAppearanceStore
    let inputSources: InputSourceService
    let loginItem: LoginItemService

    private let hud: HUDController
    private var settingsWindow: SettingsWindowController?

    init(defaults: UserDefaults = .standard) {
        settings = AppSettings(defaults: defaults)
        appearance = HUDAppearanceStore(defaults: defaults)
        inputSources = InputSourceService()
        loginItem = LoginItemService()
        hud = HUDController(settings: settings, appearance: appearance, inputSources: inputSources)
    }

    func start() {
        inputSources.onSelectionChanged = { [weak self] source in
            self?.hud.show(source)
        }
        inputSources.onSourcesChanged = { [weak self] sources in
            self?.appearance.migrateLegacyColors(for: sources)
        }

        inputSources.start()
        appearance.migrateLegacyColors(for: inputSources.sources)
    }

    func stop() {
        inputSources.stop()
    }

    // MARK: - Actions

    func showSettings() {
        loginItem.refresh()

        let controller = settingsWindow ?? SettingsWindowController(coordinator: self)
        settingsWindow = controller
        controller.show()
    }

    /// Shows the HUD for `source`, or for the current input source if `nil`.
    func previewHUD(for source: InputSource?) {
        if let source = source ?? inputSources.current {
            hud.show(source)
        }
    }

    func card(for source: InputSource) -> HUDCard {
        hud.card(for: source)
    }

    func quit() {
        NSApp.terminate(nil)
    }
}
