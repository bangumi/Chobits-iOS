import BBCode
import SwiftUI

@available(iOS 18.0, *)
struct BBCodeEditor: View {
  @Binding var text: String

  private let minHeight: CGFloat = 80
  @State private var height: CGFloat = 120
  @State private var textSelection: TextSelection?
  @State private var preview: Bool = false

  @State private var inputSize: Int = 14
  @State private var showingSizeInput = false
  private let minFontSize: Int = 8
  private let maxFontSize: Int = 50

  @State private var inputColorStart: Color = .primary
  @State private var inputColorEnd: Color = .primary
  @State private var inputColorGradient: Bool = false
  @State private var showingColorInput = false

  @State private var inputURL = ""
  @State private var showingImageInput = false
  @State private var showingURLInput = false
  @State private var showingEmojiInput = false

  private func newSelection(_ bound: String.Index, _ offset: Int, _ length: Int = 0) {
    let cursorStartIndex =
      text.index(bound, offsetBy: offset, limitedBy: text.endIndex) ?? text.endIndex
    let cursorEndIndex =
      text.index(cursorStartIndex, offsetBy: length, limitedBy: text.endIndex) ?? text.endIndex
    textSelection = TextSelection(range: cursorStartIndex..<cursorEndIndex)
  }

  private func insertTagToEnd(_ before: String, _ after: String) {
    let endIndex = text.endIndex
    text += before + after
    newSelection(endIndex, before.count)
  }

  private func handleBasicInput(_ tag: BBCodeType) {
    let tagBefore = "[\(tag.code)]"
    let tagAfter = "[/\(tag.code)]"
    if let selection = textSelection {
      switch selection.indices {
      case .selection(let range):
        if range.lowerBound == range.upperBound {
          text = text.replacingCharacters(in: range, with: tagBefore + tagAfter)
          newSelection(range.lowerBound, tagBefore.count)
        } else {
          let newText = "\(tagBefore)\(text[range])\(tagAfter)"
          if tag.isBlock {
            text.replaceSubrange(range, with: "\n\(newText)\n")
            newSelection(range.lowerBound, newText.count + 2)
          } else {
            text.replaceSubrange(range, with: newText)
            newSelection(range.lowerBound, newText.count)
          }
        }
      case .multiSelection:
        break
      @unknown default:
        break
      }
    } else {
      insertTagToEnd(tagBefore, tagAfter)
    }
  }

  private func handleImageInput() {
    let tagBefore = "[\(BBCodeType.image.code)]"
    let tagAfter = "[/\(BBCodeType.image.code)]"
    if let selection = textSelection {
      switch selection.indices {
      case .selection(let range):
        text.replaceSubrange(range, with: "\(tagBefore)\(inputURL)\(tagAfter)")
        newSelection(range.lowerBound, tagBefore.count + inputURL.count + tagAfter.count)
      case .multiSelection:
        break
      @unknown default:
        break
      }
    } else {
      insertTagToEnd("\(tagBefore)\(inputURL)\(tagAfter)", "")
    }
    inputURL = ""
  }

  private func handleURLInput() {
    if let selection = textSelection {
      switch selection.indices {
      case .selection(let range):
        let tagBefore = "[\(BBCodeType.url.code)=\(inputURL)]"
        let tagAfter = "[/\(BBCodeType.url.code)]"
        if range.lowerBound == range.upperBound {
          let placeholder = "链接描述"
          text.replaceSubrange(range, with: tagBefore + placeholder + tagAfter)
          newSelection(range.lowerBound, tagBefore.count, placeholder.count)
        } else {
          let selectedText = text[range]
          text.replaceSubrange(range, with: "\(tagBefore)\(selectedText)\(tagAfter)")
          newSelection(range.lowerBound, tagBefore.count + selectedText.count + tagAfter.count)
        }
      case .multiSelection:
        break
      @unknown default:
        break
      }
    } else {
      let endIndex = text.endIndex
      let tagBefore = "[\(BBCodeType.url.code)=\(inputURL)]"
      let tagAfter = "[/\(BBCodeType.url.code)]"
      let placeholder = "链接描述"
      text += tagBefore + placeholder + tagAfter
      newSelection(endIndex, tagBefore.count, placeholder.count)
    }
    inputURL = ""
  }

  private func handleSizeInput() {
    let tagBefore = "[\(BBCodeType.size.code)=\(inputSize)]"
    let tagAfter = "[/\(BBCodeType.size.code)]"
    if let selection = textSelection {
      switch selection.indices {
      case .selection(let range):
        if range.lowerBound == range.upperBound {
          text.replaceSubrange(range, with: tagBefore + tagAfter)
          newSelection(range.lowerBound, tagBefore.count)
        } else {
          let selectedText = text[range]
          text.replaceSubrange(range, with: "\(tagBefore)\(selectedText)\(tagAfter)")
          newSelection(range.lowerBound, tagBefore.count + selectedText.count + tagAfter.count)
        }
      case .multiSelection:
        break
      @unknown default:
        break
      }
    } else {
      insertTagToEnd(tagBefore, tagAfter)
    }
    inputSize = 14
  }

  private func convertColorToHex(_ color: Color) -> String {
    let uiColor = UIColor(color)
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    if alpha == 1 {
      return String(
        format: "#%02X%02X%02X",
        Int(red * 255),
        Int(green * 255),
        Int(blue * 255)
      )
    } else {
      return String(
        format: "#%02X%02X%02X%02X",
        Int(alpha * 255),
        Int(red * 255),
        Int(green * 255),
        Int(blue * 255)
      )
    }
  }

  private func handleColorInput() {
    let hexColor = convertColorToHex(inputColorStart)
    let tagBefore = "[\(BBCodeType.color.code)=\(hexColor)]"
    let tagAfter = "[/\(BBCodeType.color.code)]"
    if let selection = textSelection {
      switch selection.indices {
      case .selection(let range):
        if range.lowerBound == range.upperBound {
          text.replaceSubrange(range, with: tagBefore + tagAfter)
          newSelection(range.lowerBound, tagBefore.count)
        } else {
          let selectedText = text[range]
          text.replaceSubrange(range, with: "\(tagBefore)\(selectedText)\(tagAfter)")
          newSelection(range.lowerBound, tagBefore.count + selectedText.count + tagAfter.count)
        }
      case .multiSelection:
        break
      @unknown default:
        break
      }
    } else {
      insertTagToEnd(tagBefore, tagAfter)
    }
  }

  private func handleGradientInput() {
    if let selection = textSelection {
      switch selection.indices {
      case .selection(let range):
        if range.lowerBound == range.upperBound {
          break
        } else {
          // Get the selected text and its length
          let selectedText = text[range]
          let charCount = selectedText.count

          // Create a new string with gradient colors
          var gradientText = ""
          selectedText.enumerated().forEach { index, char in
            // Calculate the color for this position
            let progress = Double(index) / Double(max(1, charCount - 1))
            let currentColor = interpolateColor(
              start: inputColorStart, end: inputColorEnd, progress: progress)
            let hexColor = convertColorToHex(currentColor)

            // Add the colored character
            gradientText +=
              "[\(BBCodeType.color.code)=\(hexColor)]\(char)[/\(BBCodeType.color.code)]"
          }

          // Replace the selected text with the gradient version
          text.replaceSubrange(range, with: gradientText)
          newSelection(range.lowerBound, gradientText.count)
        }
      case .multiSelection:
        break
      @unknown default:
        break
      }
    }
  }

  private func interpolateColor(start: Color, end: Color, progress: Double) -> Color {
    let startComponents = extractColorComponents(from: start)
    let endComponents = extractColorComponents(from: end)

    let r = startComponents.r + (endComponents.r - startComponents.r) * progress
    let g = startComponents.g + (endComponents.g - startComponents.g) * progress
    let b = startComponents.b + (endComponents.b - startComponents.b) * progress
    let a = startComponents.a + (endComponents.a - startComponents.a) * progress

    return Color(uiColor: UIColor(red: r, green: g, blue: b, alpha: a))
  }

  private func extractColorComponents(from color: Color) -> (
    r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat
  ) {
    let uiColor = UIColor(color)
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
    return (r, g, b, a)
  }

  private func handleEmojiInput(_ index: Int) {
    let emoji = "(bgm\(index))"
    if let selection = textSelection {
      switch selection.indices {
      case .selection(let range):
        text.replaceSubrange(range, with: emoji)
        newSelection(range.lowerBound, emoji.count)
      case .multiSelection:
        break
      @unknown default:
        break
      }
    } else {
      let endIndex = text.endIndex
      text += emoji
      newSelection(endIndex, emoji.count)
    }
    showingEmojiInput = false
  }

  var body: some View {
    VStack {
      Button {
        preview.toggle()
      } label: {
        HStack {
          Spacer()
          Label(preview ? "返回编辑" : "预览", systemImage: preview ? "eye.slash" : "eye")
          Spacer()
        }
      }.adaptiveButtonStyle(.borderedProminent)
      if preview {
        BorderView(color: .secondary.opacity(0.2), padding: 4) {
          HStack {
            BBCodeView(text).tint(.linkText)
            Spacer()
          }
        }
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            Button(action: { showingEmojiInput = true }) {
              Image(systemName: BBCodeType.emoji.icon)
                .frame(width: 12, height: 12)
            }
            .popover(isPresented: $showingEmojiInput) {
              ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8)) {
                  ForEach(24..<126) { index in
                    Button {
                      handleEmojiInput(index)
                    } label: {
                      Image("bgm\(index)")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                    }
                  }
                }
              }
              .padding()
              .presentationCompactAdaptation(.popover)
            }
            Divider()
            ForEach(BBCodeType.basic) { code in
              Button(action: { handleBasicInput(code) }) {
                Image(systemName: code.icon)
                  .frame(width: 12, height: 12)
              }
            }
            Divider()
            Button(action: { showingImageInput = true }) {
              Image(systemName: BBCodeType.image.icon)
                .frame(width: 12, height: 12)
            }
            Button(action: { showingURLInput = true }) {
              Image(systemName: BBCodeType.url.icon)
                .frame(width: 12, height: 12)
            }
            Divider()
            Button(action: { showingSizeInput = true }) {
              Image(systemName: BBCodeType.size.icon)
                .frame(width: 12, height: 12)
            }
            Button(action: { showingColorInput = true }) {
              Image(systemName: BBCodeType.color.icon)
                .frame(width: 12, height: 12)
            }
            Divider()
            ForEach(BBCodeType.block) { code in
              Button(action: { handleBasicInput(code) }) {
                Image(systemName: code.icon)
                  .frame(width: 12, height: 12)
              }
            }
            Divider()
            ForEach(BBCodeType.alignment) { code in
              Button(action: { handleBasicInput(code) }) {
                Image(systemName: code.icon)
                  .frame(width: 12, height: 12)
              }
            }
            Divider()
          }.padding(.horizontal, 2)
        }.buttonStyle(.bordered)
        BorderView(color: .secondary.opacity(0.2), padding: 4) {
          TextEditor(text: $text, selection: $textSelection)
            .frame(height: height)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
        }
        .toolbar {
          ToolbarItem(placement: .keyboard) {
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 8) {
                ForEach(BBCodeType.basic) { code in
                  Button(action: { handleBasicInput(code) }) {
                    Image(systemName: code.icon)
                      .frame(width: 12, height: 12)
                  }
                }
                Divider()
                Button(action: { showingImageInput = true }) {
                  Image(systemName: BBCodeType.image.icon)
                    .frame(width: 12, height: 12)
                }
                Button(action: { showingURLInput = true }) {
                  Image(systemName: BBCodeType.url.icon)
                    .frame(width: 12, height: 12)
                }
                Divider()
                Button(action: { showingSizeInput = true }) {
                  Image(systemName: BBCodeType.size.icon)
                    .frame(width: 12, height: 12)
                }
                Button(action: { showingColorInput = true }) {
                  Image(systemName: BBCodeType.color.icon)
                    .frame(width: 12, height: 12)
                }
                Divider()
                ForEach(BBCodeType.block) { code in
                  Button(action: { handleBasicInput(code) }) {
                    Image(systemName: code.icon)
                      .frame(width: 12, height: 12)
                  }
                }
                Divider()
                ForEach(BBCodeType.alignment) { code in
                  Button(action: { handleBasicInput(code) }) {
                    Image(systemName: code.icon)
                      .frame(width: 12, height: 12)
                  }
                }
                Divider()
                Button(action: { showingEmojiInput = true }) {
                  Image(systemName: BBCodeType.emoji.icon)
                    .frame(width: 12, height: 12)
                }
                Divider()
              }.padding(.horizontal, 2)
            }.buttonStyle(.bordered)
          }
        }
        Rectangle()
          .fill(.secondary.opacity(0.2))
          .frame(height: 4)
          .cornerRadius(2)
          .frame(width: 40)
          .gesture(
            DragGesture()
              .onChanged { value in
                let newHeight = height + value.translation.height
                height = max(minHeight, newHeight)
              }
          ).padding(.vertical, 2)
      }
    }
    .animation(.default, value: preview)
    .alert("插入图片", isPresented: $showingImageInput) {
      TextField("图片链接", text: $inputURL)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
      Button("确定") {
        handleImageInput()
      }
      Button("取消", role: .cancel) {
        inputURL = ""
      }
    } message: {
      Text("请输入图片链接地址")
    }
    .alert("插入链接", isPresented: $showingURLInput) {
      TextField("链接地址", text: $inputURL)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
      Button("确定") {
        handleURLInput()
      }
      Button("取消", role: .cancel) {
        inputURL = ""
      }
    } message: {
      Text("请输入链接地址")
    }
    .alert("设置字号", isPresented: $showingSizeInput) {
      TextField(
        "字号",
        value: Binding(
          get: { inputSize },
          set: { inputSize = max(minFontSize, min(maxFontSize, $0)) }
        ), format: .number
      )
      .keyboardType(.numberPad)
      Button("确定") {
        handleSizeInput()
      }
      Button("取消", role: .cancel) {
        inputSize = 14
      }
    } message: {
      Text("请输入字号大小（\(minFontSize)-\(maxFontSize)）")
    }
    .sheet(isPresented: $showingColorInput) {
      ColorEditor(
        start: $inputColorStart,
        end: $inputColorEnd,
        gradient: $inputColorGradient,
        show: $showingColorInput,
        handleColorInput: handleColorInput,
        handleGradientInput: handleGradientInput
      ).presentationDetents([.medium])
    }
  }
}

struct GradientColor {
  let name: String
  let start: Color
  let end: Color

  init(_ name: String, _ start: Int, _ end: Int) {
    self.name = name
    self.start = Color(hex: start)
    self.end = Color(hex: end)
  }

  var title: AttributedString {
    var prefix = AttributedString(name.prefix(2))
    prefix.foregroundColor = start
    var suffix = AttributedString(name.dropFirst(2))
    suffix.foregroundColor = end
    return prefix + suffix
  }
}

struct ColorEditor: View {
  @Binding var start: Color
  @Binding var end: Color
  @Binding var gradient: Bool
  @Binding var show: Bool

  let handleColorInput: () -> Void
  let handleGradientInput: () -> Void

  let gradientPresets: [GradientColor] = [
    GradientColor("黄昏樱海", 0xFCEBA7, 0xC2B7FF),
    GradientColor("仙桃晴雨", 0xFFCAD3, 0x46E7D9),
    GradientColor("梦幻青绿", 0xD3F09D, 0x58BFF2),
    GradientColor("雾紫轻烟", 0xD2CAFF, 0x7DD7DD),
    GradientColor("天蓝藕粉", 0xBBD8FF, 0xFFB79C),
    GradientColor("烟粉迷紫", 0xF8C6C6, 0xC4B5F1),
    GradientColor("紫绮檬绿", 0xFFC8FB, 0xD2FFE9),
    GradientColor("莓粉天青", 0xA6E4E9, 0xF4B0EB),
  ]

  var body: some View {
    ScrollView {
      VStack {
        HStack {
          Button("取消") {
            show = false
            gradient = false
          }
          .adaptiveButtonStyle(.bordered)
          Spacer()
          Button("确定") {
            if gradient {
              handleGradientInput()
            } else {
              handleColorInput()
            }
            show = false
            gradient = false
          }
          .adaptiveButtonStyle(.borderedProminent)
        }
        HStack {
          ColorPicker("", selection: $start)
            .labelsHidden()
          if gradient {
            Rectangle()
              .fill(
                .linearGradient(
                  colors: [start, end],
                  startPoint: .leading,
                  endPoint: .trailing)
              )
              .frame(height: 32)
              .cornerRadius(16)
              .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            ColorPicker("", selection: $end)
              .labelsHidden()
          } else {
            Rectangle()
              .fill(start)
              .frame(height: 32)
              .cornerRadius(16)
              .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
          }
        }
        Toggle("渐变", isOn: $gradient)
        if gradient {
          VStack(alignment: .leading, spacing: 5) {
            ForEach(gradientPresets, id: \.name) { preset in
              HStack {
                Text(preset.title)
                Rectangle()
                  .fill(
                    .linearGradient(
                      colors: [preset.start, preset.end],
                      startPoint: .leading,
                      endPoint: .trailing)
                  )
                  .frame(height: 24)
                  .cornerRadius(12)
                  .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
              }.onTapGesture {
                start = preset.start
                end = preset.end
              }
            }
          }
        }
      }.padding()
    }
  }
}

enum BBCodeType: String, CaseIterable, Identifiable {
  case bold
  case italic
  case underline
  case strike

  case image
  case url

  case size
  case color

  case quote
  case mask
  case code

  case left
  case center
  case right

  case emoji

  var id: String { rawValue }

  static var basic: [Self] {
    [.bold, .italic, .underline, .strike]
  }

  static var block: [Self] {
    [.quote, .mask, .code]
  }

  static var alignment: [Self] {
    [.left, .center, .right]
  }

  var code: String {
    switch self {
    case .bold: return "b"
    case .italic: return "i"
    case .underline: return "u"
    case .strike: return "s"
    case .image: return "img"
    case .url: return "url"
    case .size: return "size"
    case .color: return "color"
    case .quote: return "quote"
    case .mask: return "mask"
    case .code: return "code"
    case .left: return "left"
    case .center: return "center"
    case .right: return "right"
    case .emoji: return "bgm"
    }
  }

  var icon: String {
    switch self {
    case .bold: return "bold"
    case .italic: return "italic"
    case .underline: return "underline"
    case .strike: return "strikethrough"
    case .image: return "photo"
    case .url: return "link"
    case .size: return "textformat.size"
    case .color: return "paintpalette"
    case .quote: return "text.quote"
    case .mask: return "character.square.fill"
    case .code: return "chevron.left.forwardslash.chevron.right"
    case .left: return "text.alignleft"
    case .center: return "text.aligncenter"
    case .right: return "text.alignright"
    case .emoji: return "smiley"
    }
  }

  var isBlock: Bool {
    switch self {
    case .quote, .code, .left, .center, .right: return true
    default: return false
    }
  }
}

@available(iOS 18.0, *)
#Preview {
  @Previewable @State var text = ""
  ScrollView {
    VStack {
      BBCodeEditor(text: $text)
    }.padding()
  }
}
