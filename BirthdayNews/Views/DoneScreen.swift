import SwiftUI
import UIKit

/// ③ 購入後：保存・共有・印刷・コンビニ
struct DoneScreen: View {
    let pdfURL: URL
    let name: String

    @State private var sheet: SheetKind?

    enum SheetKind: Identifiable {
        case export, share, networkPrint, sevenEleven
        var id: Int { hashValue }
    }

    /// シャープ「ネットワークプリント」の会員登録なしで使える登録ページ（ローソン・ファミリーマートなど）
    static let networkPrintURL = URL(string: "https://networkprint.ne.jp/Lite/start")!

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Theme.accent, in: Circle())
                        .accessibilityHidden(true)
                    Text("PDFができました").font(Theme.mincho(22)).foregroundStyle(Theme.ink)
                    Text("\(name)さんのお誕生日新聞\nA3・縦・1枚")
                        .font(.footnote).foregroundStyle(Theme.sub)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                VStack(spacing: 10) {
                    BigButton(title: "「ファイル」に保存", icon: "square.and.arrow.down", filled: true) { sheet = .export }
                    BigButton(title: "共有する（LINE・メールなど）", icon: "square.and.arrow.up") { sheet = .share }
                    BigButton(title: "プリンターで印刷", icon: "printer") { printPDF() }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    Text("コンビニで印刷する").font(.subheadline.bold()).foregroundStyle(Theme.ink)
                    HStack(spacing: 8) {
                        StoreButton(title: "ローソン\nファミリーマート", note: "登録ページを開く") { sheet = .networkPrint }
                        StoreButton(title: "セブン-イレブン", note: "かんたんnetprintへ渡す") { sheet = .sevenEleven }
                    }
                    Text("先に「ファイル」に保存してから押してください。印刷代は別途、コンビニでのお支払いになります。")
                        .font(.caption).foregroundStyle(Theme.sub)
                    NavigationLink("くわしい手順を見る") { GuideView() }
                        .font(.footnote.bold())
                        .frame(minHeight: 44)
                }
            }
            .padding(20)
        }
        .background(Color.white)
        .navigationTitle("保存・共有")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $sheet) { kind in
            switch kind {
            case .export:
                DocumentExporter(url: pdfURL).ignoresSafeArea()
            case .share, .sevenEleven:
                ShareSheet(items: [pdfURL]).ignoresSafeArea()
            case .networkPrint:
                SafariView(url: Self.networkPrintURL).ignoresSafeArea()
            }
        }
    }

    private func printPDF() {
        let info = UIPrintInfo(dictionary: nil)
        info.outputType = .general
        info.jobName = pdfURL.lastPathComponent
        let pc = UIPrintInteractionController.shared
        pc.printInfo = info
        pc.printingItem = pdfURL
        pc.present(animated: true, completionHandler: nil)
    }
}

struct BigButton: View {
    let title: String
    let icon: String
    var filled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 54)
                .foregroundStyle(filled ? Color.white : Theme.ink)
                .background(filled ? Theme.accent : Color.white)
                .overlay(Rectangle().stroke(filled ? Theme.accent : Theme.ink, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}

struct StoreButton: View {
    let title: String
    let note: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title).font(.subheadline.bold()).multilineTextAlignment(.center)
                Text(note).font(.caption2).foregroundStyle(Theme.sub)
            }
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity, minHeight: 76)
            .background(Theme.ground)
            .overlay(Rectangle().stroke(Theme.ink, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }
}
