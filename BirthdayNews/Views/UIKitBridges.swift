import SafariServices
import SwiftUI
import UIKit

/// 「ファイル」アプリへ保存
struct DocumentExporter: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        UIDocumentPickerViewController(forExporting: [url], asCopy: true)
    }

    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}
}

/// 共有シート（LINE・メール・かんたんnetprint など）
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

/// アプリの中で開くブラウザ
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let vc = SFSafariViewController(url: url)
        vc.preferredControlTintColor = UIColor(red: 0xA3 / 255, green: 0x24 / 255, blue: 0x1B / 255, alpha: 1)
        return vc
    }

    func updateUIViewController(_ controller: SFSafariViewController, context: Context) {}
}
