import SwiftUI

struct NoticeView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @State private var fetched: Bool = false
  @State private var updating: Bool = false
  @State private var notices: [NoticeDTO] = []
  @State private var unreadCount: Int = 0

  func loadNotice() async throws {
    let resp = try await Chii.shared.listNotice(limit: 20)
    notices = resp.data
    unreadCount = notices.count(where: { $0.unread })
  }

  func refreshNotice() async {
    do {
      try await loadNotice()
    } catch {
      Notifier.shared.alert(error: error)
    }
    fetched = true
  }

  func clearNotice() {
    if updating { return }
    updating = true
    let ids = notices.map { $0.id }
    Task {
      do {
        try await Chii.shared.clearNotice(ids: ids)
        try await loadNotice()
      } catch {
        Notifier.shared.alert(error: error)
      }
      for i in 0..<notices.count {
        notices[i].unread = false
      }
      updating = false
    }
  }

  var body: some View {
    if isAuthenticated {
      Section {
        if !fetched {
          ProgressView()
        } else {
          ScrollView {
            HStack {
              Text("全部提醒").font(.title3)
              Spacer()
              if updating {
                ZStack {
                  Button("全部已读", action: {})
                    .font(.footnote)
                    .adaptiveButtonStyle(.borderedProminent)
                    .disabled(true)
                    .hidden()
                  ProgressView()
                }
              } else {
                Button("全部已读", action: clearNotice)
                  .font(.footnote)
                  .adaptiveButtonStyle(.borderedProminent)
                  .disabled(unreadCount == 0)
              }
            }.padding(.horizontal, 8)
            LazyVStack(alignment: .leading, spacing: 10) {
              ForEach($notices) { notice in
                NoticeRowView(notice: notice)
              }
            }.padding(.horizontal, 8)
          }
          .animation(.default, value: notices)
          .refreshable {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            await refreshNotice()
          }
        }
      }
      .navigationTitle(unreadCount > 0 ? "电波提醒 (\(unreadCount))" : "电波提醒")
      .navigationBarTitleDisplayMode(.inline)
      .task {
        await refreshNotice()
      }
    } else {
      AuthView(slogan: "请登录 Bangumi 以查看通知")
    }
  }
}

#Preview {
  let container = mockContainer()

  return NoticeView()
    .modelContainer(container)
}
