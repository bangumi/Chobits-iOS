import SwiftUI
import WebKit

struct TimelineSayView: View {
  @Environment(\.dismiss) private var dismiss

  @State private var content: String = ""
  @State private var token: String = ""
  @State private var showTurnstile: Bool = false
  @State private var updating: Bool = false

  func postTimeline() async {
    do {
      updating = true
      try await Chii.shared.postTimeline(content: content, token: token)
      updating = false
      Notifier.shared.notify(message: "发送成功")
      dismiss()
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    ScrollView {
      VStack {
        HStack {
          Button {
            dismiss()
          } label: {
            Label("取消", systemImage: "xmark")
          }
          .disabled(updating)
          .adaptiveButtonStyle(.bordered)
          Spacer()
          Text("吐槽")
            .font(.headline)
          Spacer()
          Button {
            showTurnstile = true
          } label: {
            Label("发送", systemImage: "paperplane")
          }
          .disabled(content.isEmpty || updating || content.count > 380)
          .adaptiveButtonStyle(.borderedProminent)
        }
        TextInputView(type: "吐槽", text: $content)
          .textInputStyle(wordLimit: 380)
          .sheet(isPresented: $showTurnstile) {
            TurnstileSheetView(
              token: $token,
              onSuccess: {
                Task {
                  await postTimeline()
                }
              })
          }
      }.padding()
    }
  }
}
