// Xcode iOS 앱 타깃에 추가하는 진입점. 로직은 모두 TravelBudgetCore 패키지에 있다. 설정은 App/README.md 참고.
import SwiftData
import SwiftUI
import TravelBudgetCore

@main
struct TravelBudgetApp: App {
    private let container: ModelContainer
    private let currencyService: CurrencyService
    @Environment(\.scenePhase) private var scenePhase

    init() {
        do {
            let cloudKit = Bundle.main.object(forInfoDictionaryKey: "ENABLE_CLOUDKIT") as? String == "YES"
            container = try makeModelContainer(cloudKit: cloudKit)
        } catch {
            fatalError("ModelContainer 생성 실패: \(error)")
        }
        let apiKey = Bundle.main.object(forInfoDictionaryKey: "EXCHANGE_RATE_API_KEY") as? String ?? ""
        let service = CurrencyService(apiKey: apiKey, cache: FileRateCache.default)
        currencyService = service

        let container = container
        RateRefreshScheduler.register {
            await refreshStoredRates(container: container, service: service)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(currencyService: currencyService)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { RateRefreshScheduler.schedule() }
        }
    }
}
