import UIKit
import WebKit

/// 紙面をA3（297×420mm）1枚のPDFにする。
/// 画面の裏に等倍（1123×1587px）の紙面を読み込み、写真がそろったら書き出して、A3の大きさに合わせる。
@MainActor
final class PDFMaker: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    enum MakeError: LocalizedError {
        case timeout
        case page(String)
        case render

        var errorDescription: String? {
            switch self {
            case .timeout: return "紙面の準備に時間がかかっています。通信状況を確かめて、もう一度お試しください。"
            case .page(let s): return s.isEmpty ? "紙面を作れませんでした。" : s
            case .render: return "PDFを作れませんでした。もう一度お試しください。"
            }
        }
    }

    private static let sheet = CGSize(width: 1123, height: 1587)
    /// A3（ポイント。1pt = 1/72インチ）
    private static let a3 = CGRect(x: 0, y: 0, width: 841.89, height: 1190.55)

    private var continuation: CheckedContinuation<Void, Error>?

    func make(_ record: PaperRecord) async throws -> URL {
        let web = WKWebView(frame: CGRect(origin: .zero, size: Self.sheet),
                            configuration: PaperWeb.configuration(handler: self))
        web.navigationDelegate = self
        web.isUserInteractionEnabled = false
        // 画面上端の安全領域のぶんずれないように
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.scrollView.contentInset = .zero
        attachBehindContent(web)
        defer { web.removeFromSuperview() }

        // 紙面の準備（データ・写真・文字の調整）が終わるまで待つ
        try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
            continuation = c
            web.load(URLRequest(url: record.pageURL(.pdf)))
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 90_000_000_000)
                self?.finish(.failure(MakeError.timeout))
            }
        }
        // 写真が描き終わるのを少し待つ
        try? await Task.sleep(nanoseconds: 500_000_000)

        let raw: Data = try await withCheckedThrowingContinuation { c in
            let config = WKPDFConfiguration()
            config.rect = CGRect(origin: .zero, size: Self.sheet)
            web.createPDF(configuration: config) { result in
                c.resume(with: result)
            }
        }
        let pdf = try Self.fitToA3(raw)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(record.pdfFileName)
        try pdf.write(to: url, options: .atomic)
        return url
    }

    private func finish(_ result: Result<Void, Error>) {
        guard let c = continuation else { return }
        continuation = nil
        c.resume(with: result)
    }

    /// 画面には見えないよう、いちばん奥に置く（画面に載っていないと写真が描かれないことがあるため）
    private func attachBehindContent(_ view: UIView) {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        window?.insertSubview(view, at: 0)
    }

    /// 書き出したページを、A3の用紙サイズのPDFに描き直す（文字は図形のまま、拡大しても粗くならない）
    private static func fitToA3(_ data: Data) throws -> Data {
        guard let provider = CGDataProvider(data: data as CFData),
              let doc = CGPDFDocument(provider),
              let page = doc.page(at: 1) else { throw MakeError.render }
        var box = a3
        let out = NSMutableData()
        guard let consumer = CGDataConsumer(data: out as CFMutableData),
              let ctx = CGContext(consumer: consumer, mediaBox: &box, nil) else { throw MakeError.render }
        let src = page.getBoxRect(.mediaBox)
        ctx.beginPDFPage(nil)
        ctx.scaleBy(x: box.width / src.width, y: box.height / src.height)
        ctx.translateBy(x: -src.minX, y: -src.minY)
        ctx.drawPDFPage(page)
        ctx.endPDFPage()
        ctx.closePDF()
        return out as Data
    }

    // MARK: 紙面からの知らせ

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let m = PaperWeb.parse(message) else { return }
        if m.state == "ready" {
            finish(.success(()))
        } else {
            finish(.failure(MakeError.page(m.detail)))
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        finish(.failure(MakeError.render))
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        finish(.failure(MakeError.render))
    }
}
