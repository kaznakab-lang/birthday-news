import Foundation
import UniformTypeIdentifiers
import WebKit

/// アプリに入っている紙面（paper.html・js・css・data）を
/// bnews://app/… というアドレスで WKWebView に渡す。
/// （file:// のままだと紙面の JavaScript がデータを読み込めないため）
final class LocalSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "bnews"
    static let host = "app"

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url, let base = Bundle.main.resourceURL else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }
        var rel = url.path
        if rel.hasPrefix("/") { rel.removeFirst() }
        if rel.isEmpty { rel = "paper.html" }

        let fileURL = base.appendingPathComponent(rel)
        guard !rel.contains(".."), let data = try? Data(contentsOf: fileURL) else {
            let notFound = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1",
                                           headerFields: ["Content-Type": "text/plain"])!
            urlSchemeTask.didReceive(notFound)
            urlSchemeTask.didReceive(Data())
            urlSchemeTask.didFinish()
            return
        }

        var mime = UTType(filenameExtension: fileURL.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        if ["html", "css", "js", "json"].contains(fileURL.pathExtension.lowercased()) {
            mime += "; charset=utf-8"
        }
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1",
                                       headerFields: ["Content-Type": mime,
                                                      "Content-Length": String(data.count),
                                                      "Cache-Control": "no-cache"])!
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}
}

/// メッセージの受け手を弱参照で持つ（WKUserContentController が受け手を離さないため）
final class WeakMessageProxy: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?

    init(_ target: WKScriptMessageHandler) {
        self.target = target
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(userContentController, didReceive: message)
    }
}

enum PaperWeb {
    /// 紙面を表示するための設定。紙面の準備ができると "paper" に {state: "ready"} が届く。
    static func configuration(handler: WKScriptMessageHandler) -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(LocalSchemeHandler(), forURLScheme: LocalSchemeHandler.scheme)
        config.userContentController.add(WeakMessageProxy(handler), name: "paper")
        return config
    }

    /// 紙面からのメッセージを読み取る
    static func parse(_ message: WKScriptMessage) -> (state: String, detail: String)? {
        guard let body = message.body as? [String: Any], let state = body["state"] as? String else { return nil }
        return (state, body["detail"] as? String ?? "")
    }
}
