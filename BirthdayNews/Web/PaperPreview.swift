import SwiftUI
import WebKit

enum PaperLoadState: Equatable {
    case loading
    case ready
    case failed(String)
}

/// 紙面のプレビュー（画面の幅に合わせて縮小。2本指で拡大できる）
struct PaperPreview: UIViewRepresentable {
    let url: URL
    @Binding var state: PaperLoadState

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let web = WKWebView(frame: .zero, configuration: PaperWeb.configuration(handler: context.coordinator))
        web.navigationDelegate = context.coordinator
        web.isOpaque = false
        web.backgroundColor = UIColor(red: 0xE6 / 255, green: 0xE1 / 255, blue: 0xD8 / 255, alpha: 1)
        context.coordinator.loadedURL = url
        web.load(URLRequest(url: url))
        return web
    }

    func updateUIView(_ web: WKWebView, context: Context) {
        context.coordinator.parent = self
        if context.coordinator.loadedURL != url {
            context.coordinator.loadedURL = url
            DispatchQueue.main.async { state = .loading }
            web.load(URLRequest(url: url))
        }
    }

    final class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        var parent: PaperPreview
        var loadedURL: URL?

        init(_ parent: PaperPreview) {
            self.parent = parent
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let m = PaperWeb.parse(message) else { return }
            let newState: PaperLoadState = m.state == "ready" ? .ready : .failed(m.detail)
            DispatchQueue.main.async { self.parent.state = newState }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { self.parent.state = .failed("紙面を表示できませんでした。") }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { self.parent.state = .failed("紙面を表示できませんでした。") }
        }
    }
}
