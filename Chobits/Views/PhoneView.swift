import CoreSpotlight
import SwiftUI

struct PhoneView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("isolationMode") var isolationMode: Bool = false

  @State private var selectedTab: ChiiViewTab

  @State private var timelineNav: NavigationPath = NavigationPath()
  @State private var progressNav: NavigationPath = NavigationPath()
  @State private var discoverNav: NavigationPath = NavigationPath()
  @State private var rakuenNav: NavigationPath = NavigationPath()

  init() {
    let defaultTab = UserDefaults.standard.string(forKey: "defaultTab") ?? ""
    self.selectedTab = ChiiViewTab(defaultTab)
  }

  var body: some View {
    if #available(iOS 18.0, *) {
      TabView(selection: $selectedTab) {
        Tab(ChiiViewTab.timeline.title, systemImage: ChiiViewTab.timeline.icon, value: ChiiViewTab.timeline) {
          NavigationStack(path: $timelineNav) {
            ChiiTimelineView()
              .navigationDestination(for: NavDestination.self) { $0 }
          }
          .environment(
            \.openURL,
            OpenURLAction { url in
              if handleURL(url, nav: $timelineNav) {
                return .handled
              } else {
                return .systemAction
              }
            }
          )
        }

        if isAuthenticated {
          Tab(ChiiViewTab.progress.title, systemImage: ChiiViewTab.progress.icon, value: ChiiViewTab.progress) {
            NavigationStack(path: $progressNav) {
              ChiiProgressView()
                .navigationDestination(for: NavDestination.self) { $0 }
            }
            .environment(
              \.openURL,
              OpenURLAction { url in
                if handleURL(url, nav: $progressNav) {
                  return .handled
                } else {
                  return .systemAction
                }
              }
            )
          }
        }

        if !isolationMode {
          Tab(ChiiViewTab.rakuen.title, systemImage: ChiiViewTab.rakuen.icon, value: ChiiViewTab.rakuen) {
            NavigationStack(path: $rakuenNav) {
              ChiiRakuenView()
                .navigationDestination(for: NavDestination.self) { $0 }
            }
            .environment(
              \.openURL,
              OpenURLAction { url in
                if handleURL(url, nav: $rakuenNav) {
                  return .handled
                } else {
                  return .systemAction
                }
              }
            )
          }
        }

        Tab(ChiiViewTab.discover.title, systemImage: ChiiViewTab.discover.icon, value: ChiiViewTab.discover, role: .search) {
          NavigationStack(path: $discoverNav) {
            ChiiDiscoverView()
              .navigationDestination(for: NavDestination.self) { $0 }
          }
          .environment(
            \.openURL,
            OpenURLAction { url in
              if handleURL(url, nav: $discoverNav) {
                return .handled
              } else {
                return .systemAction
              }
            }
          )
          .onContinueUserActivity(CSSearchableItemActionType) { activity in
            handleSearchActivity(activity, nav: $discoverNav)
            selectedTab = .discover
          }
        }
      }
      // 允许 Tab 栏最小化
      .tabBarMinimizeBehaviorIfAvailable()
    } else {
      TabView(selection: $selectedTab) {

        NavigationStack(path: $timelineNav) {
          ChiiTimelineView()
            .navigationDestination(for: NavDestination.self) { $0 }
        }
        .tag(ChiiViewTab.timeline)
        .tabItem {
          Label(ChiiViewTab.timeline.title, systemImage: ChiiViewTab.timeline.icon)
        }
        .environment(
          \.openURL,
          OpenURLAction { url in
            if handleURL(url, nav: $timelineNav) {
              return .handled
            } else {
              return .systemAction
            }
          }
        )

        if isAuthenticated {
          NavigationStack(path: $progressNav) {
            ChiiProgressView()
              .navigationDestination(for: NavDestination.self) { $0 }
          }
          .tag(ChiiViewTab.progress)
          .tabItem {
            Label(ChiiViewTab.progress.title, systemImage: ChiiViewTab.progress.icon)
          }
          .environment(
            \.openURL,
            OpenURLAction { url in
              if handleURL(url, nav: $progressNav) {
                return .handled
              } else {
                return .systemAction
              }
            }
          )
        }

        if !isolationMode {
          NavigationStack(path: $rakuenNav) {
            ChiiRakuenView()
              .navigationDestination(for: NavDestination.self) { $0 }
          }
          .tag(ChiiViewTab.rakuen)
          .tabItem {
            Label(ChiiViewTab.rakuen.title, systemImage: ChiiViewTab.rakuen.icon)
          }
          .environment(
            \.openURL,
            OpenURLAction { url in
              if handleURL(url, nav: $rakuenNav) {
                return .handled
              } else {
                return .systemAction
              }
            }
          )
        }

        NavigationStack(path: $discoverNav) {
          ChiiDiscoverView()
            .navigationDestination(for: NavDestination.self) { $0 }
        }
        .tag(ChiiViewTab.discover)
        .tabItem {
          Label(ChiiViewTab.discover.title, systemImage: ChiiViewTab.discover.icon)
        }
        .environment(
          \.openURL,
          OpenURLAction { url in
            if handleURL(url, nav: $discoverNav) {
              return .handled
            } else {
              return .systemAction
            }
          }
        )
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
          handleSearchActivity(activity, nav: $discoverNav)
          selectedTab = .discover
        }
      }
    }
  }
}
