import SwiftUI

enum SettingsPage: String, CaseIterable, Identifiable, Hashable {
    case general
    case shortcuts
    case hud
    case inputSources
    case about

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .general: "General"
        case .shortcuts: "Shortcuts"
        case .hud: "HUD"
        case .inputSources: "Input Sources"
        case .about: "About"
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .shortcuts: "command"
        case .hud: "capsule"
        case .inputSources: "globe"
        case .about: "info.circle"
        }
    }
}

/// Which Settings page is showing; owned by the coordinator so other parts of
/// the app (menu bar, permissions prompt) can deep-link into a page.
@Observable
final class SettingsNavigation {
    var selection: SettingsPage? = .general
}

struct SettingsView: View {
    let coordinator: AppCoordinator

    var body: some View {
        @Bindable var navigation = coordinator.navigation

        NavigationSplitView {
            List(SettingsPage.allCases, selection: $navigation.selection) { page in
                // Plain symbols pick up the user's accent color and sidebar
                // icon size (HIG › Sidebars).
                Label {
                    Text(page.title)
                } icon: {
                    Image(systemName: page.symbol)
                }
                .tag(page)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
        } detail: {
            let page = navigation.selection ?? .general
            detail(for: page)
                .navigationTitle(Text(page.title))
                .id(page)
        }
        .frame(minWidth: 680, minHeight: 480)
    }

    @ViewBuilder
    private func detail(for page: SettingsPage) -> some View {
        switch page {
        case .general: GeneralSettingsView(coordinator: coordinator)
        case .shortcuts: ShortcutsSettingsView(coordinator: coordinator)
        case .hud: HUDSettingsView(coordinator: coordinator)
        case .inputSources: InputSourcesSettingsView(coordinator: coordinator)
        case .about: AboutView()
        }
    }
}
