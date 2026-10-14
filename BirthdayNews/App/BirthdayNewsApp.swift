import SwiftUI

@main
struct BirthdayNewsApp: App {
    @StateObject private var store = PaperStore()
    @StateObject private var purchases = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(purchases)
                .task {
                    purchases.store = store
                    await purchases.start()
                }
        }
    }
}

struct RootView: View {
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack { CreateView() }
                .tabItem { Label("つくる", systemImage: "plus.square") }
                .tag(0)
            NavigationStack { HistoryView() }
                .tabItem { Label("作った新聞", systemImage: "newspaper") }
                .tag(1)
            NavigationStack { GuideView() }
                .tabItem { Label("印刷のしかた", systemImage: "printer") }
                .tag(2)
        }
        .tint(Theme.accent)
    }
}
