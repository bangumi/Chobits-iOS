import Foundation
import SwiftData
import SwiftUI

enum BookChapterMode {
  case large
  case row
  case tile
}

struct ChapterData {
  let epStatus: Int
  let volStatus: Int
  let epsDesc: String
  let volumesDesc: String
}

struct ChapterState {
  let updating: Bool
  let updateButtonDisable: Bool
}

struct ChapterInputs {
  let eps: Binding<String>
  let vols: Binding<String>
}

struct ChapterActions {
  let incrEps: () -> Void
  let incrVols: () -> Void
  let update: () -> Void
}

struct SubjectBookChaptersView: View {
  let mode: BookChapterMode

  @Environment(Subject.self) var subject

  @State private var inputEps: String = ""
  @State private var eps: Int? = nil
  @State private var inputVols: String = ""
  @State private var vols: Int? = nil
  @State private var updating: Bool = false

  var updateButtonDisable: Bool {
    if updating {
      return true
    }
    return eps == nil && vols == nil
  }

  var epStatus: Int {
    return subject.interest?.epStatus ?? 0
  }

  var volStatus: Int {
    return subject.interest?.volStatus ?? 0
  }

  func parseInputEps() {
    if let newEps = Int(inputEps) {
      self.eps = newEps
    } else {
      self.eps = nil
    }
  }

  func parseInputVols() {
    if let newVols = Int(inputVols) {
      self.vols = newVols
    } else {
      self.vols = nil
    }
  }

  func incrEps() {
    if let value = eps {
      self.inputEps = "\(value+1)"
    } else {
      self.inputEps = "\(epStatus+1)"
    }
    parseInputEps()
  }

  func incrVols() {
    if let value = vols {
      self.inputVols = "\(value+1)"
    } else {
      self.inputVols = "\(volStatus+1)"
    }
    parseInputVols()
  }

  func reset() {
    self.eps = nil
    self.vols = nil
    self.inputEps = ""
    self.inputVols = ""
  }

  func update() {
    self.updating = true

    Task {
      do {
        try await Chii.shared.updateSubjectProgress(
          subjectId: subject.subjectId, eps: eps, vols: vols)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      } catch {
        Notifier.shared.alert(error: error)
      }
      self.reset()
      self.updating = false
    }
  }

  var chapterData: ChapterData {
    ChapterData(
      epStatus: epStatus,
      volStatus: volStatus,
      epsDesc: subject.epsDesc,
      volumesDesc: subject.volumesDesc
    )
  }

  var chapterState: ChapterState {
    ChapterState(
      updating: updating,
      updateButtonDisable: updateButtonDisable
    )
  }

  var chapterInputs: ChapterInputs {
    ChapterInputs(
      eps: $inputEps,
      vols: $inputVols
    )
  }

  var chapterActions: ChapterActions {
    ChapterActions(
      incrEps: incrEps,
      incrVols: incrVols,
      update: update
    )
  }

  var body: some View {
    VStack {
      switch mode {
      case .large:
        LargeChapterView(
          data: chapterData,
          state: chapterState,
          inputs: chapterInputs,
          actions: chapterActions
        )
      case .row:
        RowChapterView(
          data: chapterData,
          state: chapterState,
          inputs: chapterInputs,
          actions: chapterActions
        )
      case .tile:
        TileChapterView(
          data: chapterData,
          state: chapterState,
          inputs: chapterInputs,
          actions: chapterActions
        )
      }
    }
    .disabled(updating)
    .onChange(of: inputEps) { _, _ in parseInputEps() }
    .onChange(of: inputVols) { _, _ in parseInputVols() }
  }
}

struct LargeChapterView: View {
  let data: ChapterData
  let state: ChapterState
  let inputs: ChapterInputs
  let actions: ChapterActions

  var body: some View {
    CardView {
      HStack {
        VStack {
          HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("Chap.").foregroundStyle(.secondary)
            TextField("\(data.epStatus)", text: inputs.eps)
              .keyboardType(.numberPad)
              .frame(minWidth: 50, maxWidth: 75)
              .multilineTextAlignment(.trailing)
              .fixedSize(horizontal: true, vertical: false)
              .padding(.trailing, 2)
              .textFieldStyle(.roundedBorder)
            Text("/").foregroundStyle(.secondary)
            Text(data.epsDesc).foregroundStyle(.secondary)
              .padding(.trailing, 5)
            Button {
              actions.incrEps()
            } label: {
              Image(systemName: "plus.circle")
                .foregroundStyle(.secondary)
            }.buttonStyle(.scale)
            Spacer()
          }.monospaced()
          HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text("Vol. ").foregroundStyle(.secondary)
            TextField("\(data.volStatus)", text: inputs.vols)
              .keyboardType(.numberPad)
              .frame(minWidth: 50, maxWidth: 75)
              .multilineTextAlignment(.trailing)
              .fixedSize(horizontal: true, vertical: false)
              .padding(.trailing, 2)
              .textFieldStyle(.roundedBorder)
            Text("/").foregroundStyle(.secondary)
            Text(data.volumesDesc).foregroundStyle(.secondary)
              .padding(.trailing, 5)
            Button {
              actions.incrVols()
            } label: {
              Image(systemName: "plus.circle")
                .foregroundStyle(.secondary)
            }.buttonStyle(.scale)
            Spacer()
          }.monospaced()
        }
        Spacer()
        if state.updating {
          ZStack {
            Button("更新", action: {})
              .disabled(true)
              .hidden()
              .adaptiveButtonStyle(.borderedProminent)
            ProgressView()
          }
        } else {
          Button("更新", action: actions.update)
            .disabled(state.updateButtonDisable)
            .adaptiveButtonStyle(.borderedProminent)
        }
      }
    }
  }
}

struct RowChapterView: View {
  let data: ChapterData
  let state: ChapterState
  let inputs: ChapterInputs
  let actions: ChapterActions

  var body: some View {
    HStack {
      HStack(alignment: .firstTextBaseline, spacing: 0) {
        TextField("\(data.epStatus)", text: inputs.eps)
          .keyboardType(.numberPad)
          .frame(minWidth: 15, maxWidth: 30)
          .multilineTextAlignment(.trailing)
          .fixedSize(horizontal: true, vertical: false)
          .padding(.trailing, 2)
          .textFieldStyle(.plain)
        Text("/\(data.epsDesc)话")
          .foregroundStyle(.secondary)
          .padding(.trailing, 2)
        Button {
          actions.incrEps()
        } label: {
          Image(systemName: "plus.circle")
            .foregroundStyle(.secondary)
        }.buttonStyle(.scale)
      }
      .monospaced()
      HStack(alignment: .firstTextBaseline, spacing: 0) {
        TextField("\(data.volStatus)", text: inputs.vols)
          .keyboardType(.numberPad)
          .frame(minWidth: 15, maxWidth: 30)
          .multilineTextAlignment(.trailing)
          .fixedSize(horizontal: true, vertical: false)
          .padding(.trailing, 2)
          .textFieldStyle(.plain)
        Text("/\(data.volumesDesc)卷")
          .foregroundStyle(.secondary)
          .padding(.trailing, 2)
        Button {
          actions.incrVols()
        } label: {
          Image(systemName: "plus.circle")
            .foregroundStyle(.secondary)
        }.buttonStyle(.scale)
      }
      .monospaced()
      Spacer()
      if state.updating {
        ZStack {
          Button {
          } label: {
            Image(systemName: "checkmark.circle")
          }
          .disabled(true)
          .hidden()
          .buttonStyle(.scale)
          ProgressView()
        }
      } else {
        Button {
          actions.update()
        } label: {
          Image(systemName: "checkmark.circle")
        }
        .disabled(state.updateButtonDisable)
        .buttonStyle(.borderless)
      }
    }.font(.callout)
  }
}

struct TileChapterView: View {
  let data: ChapterData
  let state: ChapterState
  let inputs: ChapterInputs
  let actions: ChapterActions

  var body: some View {
    HStack {
      VStack {
        if state.updating {
          ZStack {
            Button {
            } label: {
              Image(systemName: "checkmark.circle")
            }
            .disabled(true)
            .hidden()
            .buttonStyle(.borderless)
            ProgressView()
          }
        } else {
          Button {
            actions.update()
          } label: {
            Image(systemName: "checkmark.circle")
          }
          .disabled(state.updateButtonDisable)
          .buttonStyle(.borderless)
        }
      }.font(.title3)
      Spacer()
      VStack(alignment: .trailing) {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
          TextField("\(data.epStatus)", text: inputs.eps)
            .keyboardType(.numberPad)
            .frame(minWidth: 32, maxWidth: 48)
            .multilineTextAlignment(.trailing)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.trailing, 2)
            .textFieldStyle(.plain)
          Text("/\(data.epsDesc)话")
            .foregroundStyle(.secondary)
            .padding(.trailing, 2)
          Button {
            actions.incrEps()
          } label: {
            Image(systemName: "plus.circle")
              .foregroundStyle(.secondary)
          }.buttonStyle(.scale)
        }.monospaced()
        HStack(alignment: .firstTextBaseline, spacing: 0) {
          TextField("\(data.volStatus)", text: inputs.vols)
            .keyboardType(.numberPad)
            .frame(minWidth: 32, maxWidth: 48)
            .multilineTextAlignment(.trailing)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.trailing, 2)
            .textFieldStyle(.plain)
          Text("/\(data.volumesDesc)卷")
            .foregroundStyle(.secondary)
            .padding(.trailing, 2)
          Button {
            actions.incrVols()
          } label: {
            Image(systemName: "plus.circle")
              .foregroundStyle(.secondary)
          }.buttonStyle(.scale)
        }.monospaced()
      }
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewBook
  container.mainContext.insert(subject)

  return ScrollView {
    LazyVStack(alignment: .leading) {
      SubjectBookChaptersView(mode: .large)
        .environment(subject)
      SubjectBookChaptersView(mode: .row)
        .environment(subject)
      HStack(spacing: 8) {
        SubjectBookChaptersView(mode: .tile)
          .environment(subject)
        Spacer()
        SubjectBookChaptersView(mode: .tile)
          .environment(subject)
      }
    }.padding()
  }.modelContainer(container)
}
