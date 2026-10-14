import SwiftUI

/// ② プレビュー（無料）→ 購入 → PDF
struct PreviewScreen: View {
    let recordID: UUID

    @EnvironmentObject private var store: PaperStore
    @EnvironmentObject private var purchases: PurchaseManager

    @State private var loadState: PaperLoadState = .loading
    @State private var busy = ""
    @State private var alert: String?
    @State private var done: DoneItem?

    struct DoneItem: Identifiable, Hashable {
        let id = UUID()
        let url: URL
        let name: String
    }

    private var record: PaperRecord? { store.record(recordID) }

    var body: some View {
        Group {
            if let record = record {
                VStack(spacing: 0) {
                    ZStack {
                        PaperPreview(url: record.pageURL(.preview), state: $loadState)
                        if loadState == .loading {
                            VStack(spacing: 10) {
                                ProgressView()
                                Text("紙面と写真を読み込んでいます…").font(.footnote).foregroundStyle(Theme.sub)
                            }
                            .padding(20)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    bottomBar(record)
                }
            } else {
                Text("この紙面は見つかりませんでした。").foregroundStyle(Theme.sub)
            }
        }
        .navigationTitle("プレビュー")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if !busy.isEmpty {
                ZStack {
                    Color.black.opacity(0.35).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView().tint(.white)
                        Text(busy).font(.callout.bold()).foregroundStyle(.white)
                    }
                }
            }
        }
        .alert("お知らせ", isPresented: Binding(get: { alert != nil }, set: { if !$0 { alert = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alert ?? "")
        }
        .navigationDestination(item: $done) { item in
            DoneScreen(pdfURL: item.url, name: item.name)
        }
    }

    @ViewBuilder
    private func bottomBar(_ record: PaperRecord) -> some View {
        VStack(spacing: 8) {
            switch loadState {
            case .failed(let msg):
                Text(msg.isEmpty ? "紙面を表示できませんでした。" : msg)
                    .font(.footnote).foregroundStyle(Theme.accent)
                    .multilineTextAlignment(.center)
            case .loading:
                Text("写真がそろうまで少しお待ちください。")
                    .font(.footnote).foregroundStyle(Theme.sub)
            case .ready:
                if record.purchased {
                    Text("購入済みの紙面です。何度でもPDFを保存できます。")
                        .font(.footnote).foregroundStyle(Theme.sub)
                } else {
                    Text("購入すると「見本」の文字が消え、A3印刷用のPDFを保存できます。")
                        .font(.footnote).foregroundStyle(Theme.sub)
                        .multilineTextAlignment(.center)
                }
            }
            Button {
                Task { await buyAndMake(record) }
            } label: {
                Text(buttonTitle(record))
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .foregroundStyle(.white)
                    .background(loadState == .ready ? Theme.accent : Theme.sub.opacity(0.5))
            }
            .disabled(loadState != .ready || !busy.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .background(.white)
        .overlay(alignment: .top) { Divider() }
    }

    private func buttonTitle(_ record: PaperRecord) -> String {
        if record.purchased { return "A3印刷用PDFを作る" }
        let price = purchases.priceText
        return price.isEmpty ? "A3印刷用PDFを保存" : "A3印刷用PDFを保存　\(price)"
    }

    private func buyAndMake(_ record: PaperRecord) async {
        if !record.purchased {
            busy = "購入の手続き中…"
            let outcome = await purchases.buy(recordID: record.id)
            busy = ""
            switch outcome {
            case .success:
                break
            case .cancelled:
                return
            case .pending:
                alert = "購入の承認待ちです。承認されると、この紙面のPDFを保存できるようになります。"
                return
            case .failed(let msg):
                alert = msg
                return
            }
        }
        guard let current = store.record(record.id), current.purchased else { return }
        busy = "PDFを作っています…"
        let maker = PDFMaker()
        do {
            let url = try await maker.make(current)
            busy = ""
            done = DoneItem(url: url, name: current.name)
        } catch {
            busy = ""
            alert = error.localizedDescription
        }
    }
}
