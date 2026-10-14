import SwiftUI

/// ⑤ 印刷のしかた
struct GuideView: View {
    private struct Step: Identifiable {
        let id: Int
        let title: String
        let detail: String
    }

    private let lawson: [Step] = [
        Step(id: 1, title: "PDFを「ファイル」に保存", detail: "紙面を購入して、「ファイル」に保存します。"),
        Step(id: 2, title: "登録ページを開く", detail: "保存後の画面の「ローソン・ファミリーマート」を押すと、シャープのネットワークプリントの登録ページ（会員登録なし）が開きます。"),
        Step(id: 3, title: "PDFを選んで登録", detail: "利用規約に同意し、「ファイルを選ぶ」で保存した新聞のPDFを選びます。表示されたユーザー番号を、スクリーンショットなどで控えます。"),
        Step(id: 4, title: "お店で印刷", detail: "マルチコピー機で「ネットワークプリント」を選び、番号を入れて、A3・カラーで印刷します。")
    ]

    private let seven: [Step] = [
        Step(id: 1, title: "かんたんnetprintへ渡す", detail: "保存後の画面の「セブン-イレブン」を押し、共有の一覧から「かんたんnetprint」を選びます（App Storeで無料で入手できます）。"),
        Step(id: 2, title: "A3を選んで登録", detail: "用紙サイズはA3を選んで登録します。表示された予約番号を控えます。"),
        Step(id: 3, title: "お店で印刷", detail: "マルチコピー機で「ネットプリント」を選び、予約番号を入れて、カラーで印刷します。")
    ]

    var body: some View {
        List {
            Section("ローソン・ファミリーマートで印刷する") {
                ForEach(lawson) { stepRow($0) }
            }
            Section("セブン-イレブンで印刷する") {
                ForEach(seven) { stepRow($0) }
            }
            Section("うまく印刷するコツ") {
                Text("用紙サイズは必ずA3を選んでください。A4を選ぶと縮小されて文字が小さくなります。")
                Text("印刷代は別途、コンビニでのお支払いになります。登録したデータは、各サービスの期限が過ぎると消えます。")
            }
            .font(.callout)
            .foregroundStyle(Theme.ink)
            Section("家のプリンターで印刷する") {
                Text("A3に対応したプリンターなら、保存後の画面の「プリンターで印刷」から印刷できます。")
                    .font(.callout)
                    .foregroundStyle(Theme.ink)
            }
        }
        .navigationTitle("印刷のしかた")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stepRow(_ s: Step) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(s.id)")
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Theme.ink)
            VStack(alignment: .leading, spacing: 3) {
                Text(s.title).font(.subheadline.bold()).foregroundStyle(Theme.ink)
                Text(s.detail).font(.footnote).foregroundStyle(Theme.sub)
            }
        }
        .padding(.vertical, 2)
    }
}
