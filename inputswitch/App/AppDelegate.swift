import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let coordinator = AppCoordinator()

    private var launchedAsLoginItem = false

    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        launchedAsLoginItem = Self.detectLoginItemLaunch()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !Self.isRunningTests else { return }
        coordinator.start()

        // Opening the app by hand (Finder, Launchpad, Spotlight) shows Settings;
        // launching silently at login does not.
        let defaults = UserDefaults.standard
        let isFirstLaunch = !defaults.bool(forKey: DefaultsKey.hasLaunchedBefore)
        defaults.set(true, forKey: DefaultsKey.hasLaunchedBefore)
        if isFirstLaunch || !launchedAsLoginItem {
            coordinator.showSettings()
        }
    }

    /// Clicking the app icon again while it is running opens Settings.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        coordinator.showSettings()
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator.stop()
    }

    private static func detectLoginItemLaunch() -> Bool {
        let event = NSAppleEventManager.shared().currentAppleEvent
        if event?.eventID == kAEOpenApplication,
           event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem {
            return true
        }
        // `SMAppService` launches don't always carry the Apple Event marker;
        // treat a launch shortly after boot as a login launch when enabled.
        let loginItemEnabled = LoginItemService().isEnabled
        return loginItemEnabled && ProcessInfo.processInfo.systemUptime < 180
    }
}
