import SwiftUI

/// ① つくる（入力）
struct CreateView: View {
    @EnvironmentObject private var store: PaperStore

    @State private var name = ""
    @State private var year: Int?
    @State private var month: Int?
    @State private var day: Int?
    @State private var intro = ""
    @State private var message = ""
    @State private var from = ""
    @State private var error = ""
    @State private var opened: PaperRecord?
    @FocusState private var focus: Field?

    /// 入力欄（キーボードを閉じるため）
    enum Field: Hashable { case name, intro, message, from }

    static let minYear = 1930
    static let maxYear = 2025

    private var dayCount: Int {
        let y = year ?? 2000
        let m = month ?? 1
        var c = DateComponents()
        c.year = y
        c.month = m
        let cal = Calendar(identifier: .gregorian)
        guard let date = cal.date(from: c), let range = cal.range(of: .day, in: .month, for: date) else { return 31 }
        return range.count
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    Daiji()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("生まれた日の記念新聞").font(Theme.mincho(20)).foregroundStyle(Theme.ink)
                        Text("生年月日を入れるだけで、その日のニュースと写真でつくるA3の記念新聞。")
                            .font(.footnote).foregroundStyle(Theme.sub)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("主役のお名前") {
                TextField("山田 花子", text: $name)
                    .textContentType(.name)
                    .focused($focus, equals: .name)
                    .submitLabel(.done)
                    .onSubmit { focus = nil }
                    .onChange(of: name) { _, v in if v.count > 20 { name = String(v.prefix(20)) } }
            }

            Section {
                Picker("年", selection: $year) {
                    Text("年を選ぶ").tag(Int?.none)
                    ForEach(Array((Self.minYear...Self.maxYear).reversed()), id: \.self) { y in
                        Text("\(String(y))年（\(Theme.wareki(y))）").tag(Int?.some(y))
                    }
                }
                Picker("月", selection: $month) {
                    Text("選ぶ").tag(Int?.none)
                    ForEach(1...12, id: \.self) { m in Text("\(m)月").tag(Int?.some(m)) }
                }
                Picker("日", selection: $day) {
                    Text("選ぶ").tag(Int?.none)
                    ForEach(1...dayCount, id: \.self) { d in Text("\(d)日").tag(Int?.some(d)) }
                }
            } header: {
                Text("生年月日")
            } footer: {
                Text("\(String(Self.minYear))〜\(String(Self.maxYear))年生まれに対応しています")
            }
            .onChange(of: year) { _, _ in clampDay() }
            .onChange(of: month) { _, _ in clampDay() }

            Section {
                TextField("小さいころから本が大好き。", text: $intro, axis: .vertical)
                    .lineLimit(2...4)
                    .focused($focus, equals: .intro)
                    .onChange(of: intro) { _, v in if v.count > 100 { intro = String(v.prefix(100)) } }
            } header: {
                Text("主役のひとこと紹介（任意・100字まで）")
            } footer: {
                Text("紙面の「誕生日によせて」欄に入ります")
            }

            Section("お祝いのメッセージ（任意・160字まで）") {
                TextField("お誕生日おめでとう！", text: $message, axis: .vertical)
                    .lineLimit(2...5)
                    .focused($focus, equals: .message)
                    .onChange(of: message) { _, v in if v.count > 160 { message = String(v.prefix(160)) } }
            }

            Section("贈り主のお名前（任意）") {
                TextField("家族一同", text: $from)
                    .focused($focus, equals: .from)
                    .submitLabel(.done)
                    .onSubmit { focus = nil }
                    .onChange(of: from) { _, v in if v.count > 20 { from = String(v.prefix(20)) } }
            }

            Section {
                if !error.isEmpty {
                    Text(error).font(.footnote.bold()).foregroundStyle(Theme.accent)
                }
                Button(action: create) {
                    Text("紙面をつくる（無料）")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .foregroundStyle(.white)
                        .background(Theme.accent)
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets())
            } footer: {
                Text("紙面の確認は無料です。印刷用のPDFを保存するときにお支払いいただきます。")
            }
        }
        // 下へスクロールしたとき、キーボード上の「完了」を押したときにキーボードを閉じる
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") { focus = nil }
            }
        }
        .navigationTitle("つくる")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $opened) { r in
            PreviewScreen(recordID: r.id)
        }
    }

    private func clampDay() {
        if let d = day, d > dayCount { day = nil }
    }

    private func create() {
        focus = nil
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !n.isEmpty else { error = "お名前を入れてください"; return }
        guard let y = year else { error = "生まれた年を選んでください"; return }
        guard let m = month else { error = "生まれた月を選んでください"; return }
        guard let d = day else { error = "生まれた日を選んでください"; return }
        error = ""
        let r = PaperRecord(name: n, year: y, month: m, day: d,
                            intro: intro.trimmingCharacters(in: .whitespacesAndNewlines),
                            message: message.trimmingCharacters(in: .whitespacesAndNewlines),
                            from: from.trimmingCharacters(in: .whitespacesAndNewlines))
        opened = store.add(r)
    }
}
