import OSLog
import SwiftData
import SwiftUI

struct ContentView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("friendlist") var friendlist: [Int] = []
  @AppStorage("blocklist") var blocklist: [Int] = []

  @State var notifier = Notifier.shared

  func refreshProfile() async {
    if !isAuthenticated {
      return
    }
    var tries = 0
    while true {
      if tries > 3 {
        break
      }
      tries += 1
      do {
        profile = try await Chii.shared.getProfile()
        await Chii.shared.setAuthStatus(true)
        Logger.api.info("refresh profile success: \(profile.rawValue)")
        return
      } catch ChiiError.requireLogin {
        Notifier.shared.notify(message: "请登录")
        await Chii.shared.setAuthStatus(false)
        return
      } catch {
        Notifier.shared.notify(message: "获取当前用户信息失败，重试 \(tries)/3")
        Logger.api.warning("refresh profile failed: \(error)")
      }
      sleep(2)
    }
    Notifier.shared.alert(message: "无法获取当前用户信息，请重新登录")
    await Chii.shared.setAuthStatus(false)
  }

  func refreshRelationships() async {
    if !isAuthenticated {
      return
    }
    do {
      friendlist = try await Chii.shared.getFriendList()
      blocklist = try await Chii.shared.getBlockList()
    } catch {
      Notifier.shared.notify(message: "获取好友/黑名单列表失败")
      Logger.api.warning("refresh relationships failed: \(error)")
    }
  }

  var body: some View {
    ZStack {
      if UIDevice.current.userInterfaceIdiom == .pad, #available(iOS 18.0, *) {
        PadView()
      } else {
        PhoneView()
      }
      VStack(alignment: .center) {
        ForEach($notifier.notifications, id: \.self) { $notification in
          Text(notification)
            .padding(8)
            .foregroundStyle(.white)
            .background(.accent)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 10)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        Spacer()
      }
      .animation(.default, value: notifier.notifications)
      .padding(.horizontal, 8)
      .padding(.top, 64)
      .alert("ERROR", isPresented: $notifier.hasAlert) {
        Button("OK") {
          Notifier.shared.vanishError()
        }
        Button("Copy") {
          UIPasteboard.general.string = notifier.currentError?.description
          Notifier.shared.notify(message: "已复制")
        }
      } message: {
        if let error = notifier.currentError {
          Text(verbatim: String(describing: error))
        } else {
          Text("Unknown Error")
        }
      }
    }
    .task {
      await refreshProfile()
      await refreshRelationships()
    }
  }
}
