import Flow
import SwiftData
import SwiftUI

struct SubjectCollectionBoxView: View {
  @AppStorage("autoCompleteProgress") var autoCompleteProgress: Bool = false

  @Environment(\.modelContext) var modelContext
  @Environment(\.dismiss) private var dismiss
  @Environment(Subject.self) var subject

  @State private var ctype: CollectionType = .none
  @State private var rate: Int = 0
  @State private var comment: String = ""
  @State private var priv: Bool = false
  @State private var tags: Set<String> = Set()
  @State private var tagsInput: String = ""

  @State private var updating: Bool = false

  var recommendedTags: [String] {
    return subject.tags.sorted(by: { $0.count > $1.count }).prefix(15).map { $0.name }
  }

  var buttonText: String {
    if subject.ctype != 0 {
      return priv ? "悄悄地更新" : "更新"
    } else {
      return priv ? "悄悄地添加" : "添加"
    }
  }

  var ratingComment: String {
    if rate == 10 {
      return "\(rate.ratingDescription) \(rate) (请谨慎评价)"
    }
    if rate > 0 {
      return "\(rate.ratingDescription) \(rate)"
    }
    return ""
  }

  var submitDisabled: Bool {
    return ctype == .none || comment.count > 380
  }

  func load() {
    if let interest = subject.interest {
      self.ctype = interest.type
      self.rate = interest.rate
      self.comment = interest.comment
      self.priv = interest.private
      self.tags = Set(interest.tags)
    }
  }

  func updateTags() {
    let inputTags = tagsInput.split(separator: " ").map { String($0) }
    tags.formUnion(inputTags)
    tagsInput = ""
  }

  func update() {
    self.updating = true
    Task {
      do {
        try await Chii.shared.updateSubjectCollection(
          subjectId: subject.subjectId,
          type: ctype,
          rate: rate,
          comment: comment,
          priv: priv,
          tags: Array(tags.sorted().prefix(10)),
          progress: autoCompleteProgress
        )
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
      } catch {
        Notifier.shared.alert(error: error)
      }
      self.updating = false
    }
  }

  var body: some View {
    ScrollView {
      VStack {
        HStack {
          Button(action: update) {
            Spacer()
            Text(buttonText)
            Spacer()
          }.adaptiveButtonStyle(.borderedProminent)
          Toggle(isOn: $priv) {
            Image(systemName: priv ? "lock" : "lock.open")
          }
          .toggleStyle(.button)
          .adaptiveButtonStyle(.borderedProminent)
          .frame(width: 40)
          .sensoryFeedback(.selection, trigger: priv)
        }
        .disabled(submitDisabled)
        .padding(.vertical, 5)
        if let interest = subject.interest, interest.updatedAt > 0 {
          Section {
            Text("上次更新：\(interest.updatedAt.datetimeDisplay)")
              + Text(" / \(interest.updatedAt.date, style: .relative)前")
              .foregroundStyle(.secondary)
          }
          .monospacedDigit()
          .font(.caption)
        }

        Picker("CollectionType", selection: $ctype) {
          ForEach(CollectionType.allTypes()) { ct in
            Text("\(ct.description(subject.typeEnum))").tag(ct)
          }
        }
        .pickerStyle(.segmented)

        VStack(alignment: .leading) {
          HStack(alignment: .top) {
            Text("我的评价:")
            Text(ratingComment)
              .foregroundStyle(rate > 0 ? .red : .secondary)
          }
          .padding(.top, 10)
          HStack {
            Image(systemName: "star.slash")
              .resizable()
              .foregroundStyle(.secondary)
              .frame(width: 20, height: 20)
              .onTapGesture {
                rate = 0
              }
            ForEach(1..<11) { idx in
              Image(systemName: rate >= idx ? "star.fill" : "star")
                .resizable()
                .foregroundStyle(.orange)
                .frame(width: 20, height: 20)
                .onTapGesture {
                  rate = Int(idx)
                }
            }
          }

          Text("标签 (使用半角空格或逗号隔开，至多10个)")
            .font(.footnote)
            .padding(.top, 10)

          HFlow(alignment: .center, spacing: 4) {
            ForEach(Array(tags.sorted().prefix(10)), id: \.self) { tag in
              BorderView(padding: 2) {
                Button {
                  tags.remove(tag)
                } label: {
                  Label(tag, systemImage: "xmark.circle")
                    .labelStyle(.compact)
                }
              }
              .font(.caption)
              .foregroundStyle(.secondary)
            }
          }.padding(.top, 2)

          BorderView(color: .secondary.opacity(0.2), padding: 4) {
            HStack {
              TextField("标签", text: $tagsInput)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit {
                  updateTags()
                }
              Button {
                updateTags()
              } label: {
                Image(systemName: "plus.circle")
              }.disabled(tagsInput.isEmpty)
            }
          }

          VStack(alignment: .leading, spacing: 2) {
            Text("常用标签:").font(.footnote).foregroundStyle(.secondary)
            HFlow(alignment: .center, spacing: 2) {
              ForEach(recommendedTags, id: \.self) { tag in
                Button {
                  tags.insert(tag)
                } label: {
                  if tags.contains(tag) {
                    Label(tag, systemImage: "checkmark.circle")
                      .labelStyle(.compact)
                  } else {
                    Label(tag, systemImage: "plus.circle")
                      .labelStyle(.compact)
                  }
                }
                .disabled(tags.contains(tag))
                .font(.caption)
                .lineLimit(1)
                .padding(.vertical, 2)
                .padding(.horizontal, 4)
                .foregroundStyle(.secondary.opacity(tags.contains(tag) ? 0.6 : 1))
                .background(.secondary.opacity(tags.contains(tag) ? 0.3 : 0.1))
                .cornerRadius(5)
                .padding(1)
              }
            }
          }

          Text("吐槽")
          TextInputView(type: "吐槽", text: $comment)
            .textInputStyle(wordLimit: 380)
        }
        Spacer()
      }
      .onAppear(perform: load)
      .disabled(updating)
      .animation(.default, value: priv)
      .animation(.default, value: rate)
      .padding()
    }
  }
}

#Preview {
  let container = mockContainer()

  let subject = Subject.previewBook
  container.mainContext.insert(subject)

  return SubjectCollectionBoxView()
    .environment(subject)
    .modelContainer(container)
}
