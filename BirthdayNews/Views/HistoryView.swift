import SwiftUI

/// ④ 作った新聞
struct HistoryView: View {
    @EnvironmentObject private var store: PaperStore

    private static let dateFormat: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ja_JP")
        f.dateFormat = "yyyy年M月d日"
        return f
    }()

    var body: some View {
        Group {
            if store.records.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "newspaper").font(.system(size: 40)).foregroundStyle(Theme.sub)
                        .accessibilityHidden(true)
                    Text("まだ紙面はありません").font(.headline).foregroundStyle(Theme.ink)
                    Text("「つくる」から、最初の一枚をつくりましょう。").font(.footnote).foregroundStyle(Theme.sub)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    Section {
                        ForEach(store.records) { r in
                            NavigationLink {
                                PreviewScreen(recordID: r.id)
                            } label: {
                                row(r)
                            }
                        }
                        .onDelete { store.delete(at: $0) }
                    } footer: {
                        Text("購入済みの紙面は、何度でもPDFを保存し直せます。未購入の紙面はプレビューのみです。")
                    }
                }
            }
        }
        .navigationTitle("作った新聞")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ r: PaperRecord) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("\(r.name)さん").font(.body.bold()).foregroundStyle(Theme.ink)
                Text("\(r.birthLabel)生まれ").font(.footnote).foregroundStyle(Theme.sub)
                Text("作成 \(Self.dateFormat.string(from: r.createdAt))").font(.caption).foregroundStyle(Theme.sub)
            }
            Spacer()
            Text(r.purchased ? "購入済み" : "プレビュー")
                .font(.caption.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .foregroundStyle(r.purchased ? Theme.accent : Theme.sub)
                .overlay(Rectangle().stroke(r.purchased ? Theme.accent : Theme.sub, lineWidth: 1))
        }
        .padding(.vertical, 4)
    }
}
