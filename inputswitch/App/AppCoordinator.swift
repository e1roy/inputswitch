import AppKit
import Observation

/// Composition root: owns every service and wires their events together.
///
/// ```
/// HotKeyMonitor ──switch──▶ InputSourceService ──changed──▶ HUDController
///        └──────show HUD──────────────────────────────────▶ HUDController
/// AppSettings / HUDAppearanceStore ──read by──▶ HotKeyMonitor, HUDController
/// ```
@Observable
final class AppCoordinator {
    let settings: AppSettings
    let appearance: HUDAppearanceStore
    let inputSources: InputSourceService
    let loginItem: LoginItemService
    let accessibility: AccessibilityPermission
    let navigation = SettingsNavigation()

    @ObservationIgnored private let hotKeys: HotKeyMonitor
    @ObservationIgnored private let hud: HUDController
    @ObservationIgnored private var settingsWindow: SettingsWindowController?

    init(defaults: UserDefaults = .standard) {
        settings = AppSettings(defaults: defaults)
        appearance = HUDAppearanceStore(defaults: defaults)
        inputSources = InputSourceService()
        loginItem = LoginItemService()
        accessibility = AccessibilityPermission()
        hotKeys = HotKeyMonitor(settings: settings)
        hud = HUDController(settings: settings, appearance: appearance, inputSources: inputSources)
    }

    func start() {
        inputSources.onSelectionChanged = { [weak self] source in
            self?.hud.show(source)
        }
        inputSources.onSourcesChanged = { [weak self] sources in
            self?.appearance.migrateLegacyColors(for: sources)
        }
        hotKeys.onSwitchRequested = { [weak self] in
            self?.inputSources.selectNext()
        }
        hotKeys.onShowHUDRequested = { [weak self] in
            self?.showCurrentInputSource()
        }
        accessibility.onGranted = { [weak self] in
            // Monitors installed before trust was granted never receive events.
            self?.hotKeys.restart()
        }

        inputSources.start()
        appearance.migrateLegacyColors(for: inputSources.sources)
        hotKeys.start()
        accessibility.startMonitoring()
    }

    func stop() {
        hotKeys.stop()
        inputSources.stop()
    }

    // MARK: - Actions

    func showSettings(_ page: SettingsPage? = nil) {
        if let page { navigation.selection = page }
        loginItem.refresh()
        accessibility.startMonitoring()

        let controller = settingsWindow ?? SettingsWindowController(coordinator: self)
        settingsWindow = controller
        controller.show()
    }

    func showCurrentInputSource() {
        inputSources.refresh()
        if let current = inputSources.current {
            hud.show(current)
        }
    }

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
