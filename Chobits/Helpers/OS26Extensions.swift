import SwiftUI

// MARK: - OS 26.0+ 液态玻璃扩展

extension View {
  /// 应用和配置液态玻璃效果
  /// https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views#Apply-and-configure-Liquid-Glass-effects
  @ViewBuilder
  func glassEffectIfAvailable(tint: Color, shape: some Shape) -> some View {
    if #available(iOS 26.0, *) {
      self.glassEffect(.regular.tint(tint), in: shape)
    } else {
      self
    }
  }
  
  /// 按钮样式选择器
  /// 在 OS 26+ 使用液态玻璃效果，否则使用指定的样式
  @ViewBuilder
  func adaptiveButtonStyle(_ style: ButtonStyleType) -> some View {
    if #available(iOS 26.0, *) {
      switch style {
      case .bordered:
        self.buttonStyle(.glass)
      case .borderedProminent:
        self.buttonStyle(.glassProminent)
      case .plain:
        self.buttonStyle(.glass)
      case .borderless:
        self.buttonStyle(.glass)
      }
    } else {
      switch style {
      case .bordered:
        self.buttonStyle(.bordered)
      case .borderedProminent:
        self.buttonStyle(.borderedProminent)
      case .plain:
        self.buttonStyle(.plain)
      case .borderless:
        self.buttonStyle(.borderless)
      }
    }
  }
  
  /// 设置 TabBar 最小化行为
  /// https://developer.apple.com/documentation/swiftui/view/tabbarminimizebehavior(_:)
  @ViewBuilder
  func tabBarMinimizeBehaviorIfAvailable() -> some View {
    if #available(iOS 26.0, *) {
      self.tabBarMinimizeBehavior(.onScrollDown)
    } else {
      self
    }
  }
}

// MARK: - 按钮样式类型枚举
enum ButtonStyleType {
  case bordered
  case borderedProminent
  case plain
  case borderless
}