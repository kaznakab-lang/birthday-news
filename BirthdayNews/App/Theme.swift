import SwiftUI

/// 紙面と同じ色。背景は白。
enum Theme {
    static let ink = Color(red: 0x22 / 255, green: 0x20 / 255, blue: 0x1C / 255)
    static let accent = Color(red: 0xA3 / 255, green: 0x24 / 255, blue: 0x1B / 255)
    static let sub = Color(red: 0x5A / 255, green: 0x54 / 255, blue: 0x4A / 255)
    static let ground = Color(red: 0xF6 / 255, green: 0xF1 / 255, blue: 0xE6 / 255)

    /// 見出し用の明朝風（端末の明朝体）
    static func mincho(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .serif)
    }

    /// 和暦（ラベル用。年の途中で改元した年は両方を書く）
    static func wareki(_ y: Int) -> String {
        if y >= 2019 { return y == 2019 ? "平成31・令和元年" : "令和\(y - 2018)年" }
        if y >= 1989 { return y == 1989 ? "昭和64・平成元年" : "平成\(y - 1988)年" }
        return "昭和\(y - 1925)年"
    }
}

/// 題字（赤い四角に「誕生 日報」）
struct Daiji: View {
    var size: CGFloat = 15
    var body: some View {
        Text("誕生\n日報")
            .font(Theme.mincho(size))
            .multilineTextAlignment(.center)
            .lineSpacing(-2)
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .background(Theme.accent)
            .accessibilityLabel("誕生日報")
    }
}
