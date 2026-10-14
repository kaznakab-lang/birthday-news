import Foundation

/// 1枚の紙面（入力した内容と、購入済みかどうか）
struct PaperRecord: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var year: Int
    var month: Int
    var day: Int
    var intro: String
    var message: String
    var from: String
    var createdAt: Date
    var purchased: Bool

    init(name: String, year: Int, month: Int, day: Int, intro: String, message: String, from: String) {
        self.id = UUID()
        self.name = name
        self.year = year
        self.month = month
        self.day = day
        self.intro = intro
        self.message = message
        self.from = from
        self.createdAt = Date()
        self.purchased = false
    }

    var dateString: String { String(format: "%04d-%02d-%02d", year, month, day) }
    var birthLabel: String { "\(year)年\(month)月\(day)日" }

    /// 同じ内容の紙面かどうか（購入済みのものを作り直したときに二重に払わないため）
    func sameContent(_ o: PaperRecord) -> Bool {
        name == o.name && year == o.year && month == o.month && day == o.day
            && intro == o.intro && message == o.message && from == o.from
    }

    enum Mode { case preview, pdf }

    /// アプリ内の紙面ページのURL
    func pageURL(_ mode: Mode) -> URL {
        var items: [(String, String)] = [("d", dateString), ("n", name)]
        if !intro.isEmpty { items.append(("i", intro)) }
        if !message.isEmpty { items.append(("m", message)) }
        if !from.isEmpty { items.append(("f", from)) }
        switch mode {
        case .preview:
            items.append(("app", "1"))
            if !purchased { items.append(("wm", "1")) }
        case .pdf:
            items.append(("pdf", "1"))
        }
        let query = items.map { "\($0.0)=\(Self.encode($0.1))" }.joined(separator: "&")
        return URL(string: "\(LocalSchemeHandler.scheme)://\(LocalSchemeHandler.host)/paper.html?\(query)")!
    }

    var pdfFileName: String {
        let bad = CharacterSet(charactersIn: "/\\:?*\"<>|")
        let safe = name.components(separatedBy: bad).joined()
        return "お誕生日新聞_\(safe.isEmpty ? "紙面" : safe)_\(dateString).pdf"
    }

    /// 英数字と - . _ ~ 以外はすべて %xx にする（日本語や + も）
    private static let safe = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")

    private static func encode(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: safe) ?? ""
    }
}

/// 作った紙面の一覧（端末の中だけに保存）
@MainActor
final class PaperStore: ObservableObject {
    @Published private(set) var records: [PaperRecord] = []
    private let key = "papers.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let list = try? JSONDecoder().decode([PaperRecord].self, from: data) {
            records = list
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    /// 新しく作る。同じ内容がすでにあれば、それを先頭に出して使う。
    func add(_ r: PaperRecord) -> PaperRecord {
        if let i = records.firstIndex(where: { $0.sameContent(r) }) {
            var existing = records.remove(at: i)
            existing.createdAt = Date()
            records.insert(existing, at: 0)
            save()
            return existing
        }
        records.insert(r, at: 0)
        save()
        return r
    }

    func record(_ id: UUID) -> PaperRecord? {
        records.first { $0.id == id }
    }

    func markPurchased(_ id: UUID) {
        guard let i = records.firstIndex(where: { $0.id == id }) else { return }
        records[i].purchased = true
        save()
    }

    func delete(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        save()
    }
}
