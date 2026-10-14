import Foundation
import StoreKit

/// 印刷用PDFの購入（App内課金・消耗型。1枚ごとに購入）
@MainActor
final class PurchaseManager: ObservableObject {
    /// App Store Connect で作る商品ID。必ずこれと同じにする。
    static let productID = "com.kutalabo.birthdaynews.pdf"

    @Published private(set) var product: Product?
    weak var store: PaperStore?

    /// 購入処理の途中でアプリが閉じても、どの紙面の購入かを覚えておく
    private let pendingKey = "purchase.pendingRecord"
    private var updatesTask: Task<Void, Never>?

    enum Outcome {
        case success
        case cancelled
        case pending
        case failed(String)
    }

    func start() async {
        if updatesTask == nil {
            updatesTask = Task { [weak self] in
                for await result in Transaction.updates {
                    await self?.handle(result)
                }
            }
        }
        for await result in Transaction.unfinished {
            await handle(result)
        }
        await loadProduct()
    }

    func loadProduct() async {
        do {
            product = try await Product.products(for: [Self.productID]).first
        } catch {
            product = nil
        }
    }

    /// 表示用の値段（読み込めないときは空）
    var priceText: String { product?.displayPrice ?? "" }

    func buy(recordID: UUID) async -> Outcome {
        if product == nil { await loadProduct() }
        guard let product = product else {
            return .failed("商品情報を読み込めませんでした。通信状況を確かめて、もう一度お試しください。")
        }
        UserDefaults.standard.set(recordID.uuidString, forKey: pendingKey)
        do {
            // どの紙面の購入かを、購入そのものに書き添えておく（承認待ちのあとでも取り違えないため）
            let result = try await product.purchase(options: [.appAccountToken(recordID)])
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    store?.markPurchased(recordID)
                    UserDefaults.standard.removeObject(forKey: pendingKey)
                    await transaction.finish()
                    return .success
                case .unverified(let transaction, _):
                    UserDefaults.standard.removeObject(forKey: pendingKey)
                    await transaction.finish()
                    return .failed("購入を確認できませんでした。もう一度お試しください。")
                }
            case .userCancelled:
                UserDefaults.standard.removeObject(forKey: pendingKey)
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .failed("購入を完了できませんでした。")
            }
        } catch {
            return .failed("購入を完了できませんでした。（\(error.localizedDescription)）")
        }
    }

    /// あとから届いた購入（承認待ちだった購入など）を、覚えておいた紙面に反映する
    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else {
            if case .unverified(let t, _) = result { await t.finish() }
            return
        }
        if transaction.productID == Self.productID {
            if let id = transaction.appAccountToken {
                store?.markPurchased(id)
            } else if let s = UserDefaults.standard.string(forKey: pendingKey), let id = UUID(uuidString: s) {
                store?.markPurchased(id)
            }
            UserDefaults.standard.removeObject(forKey: pendingKey)
        }
        await transaction.finish()
    }
}
