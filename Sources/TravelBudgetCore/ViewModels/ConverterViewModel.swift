import Foundation
import Observation

/// 현지 통화 ↔ 기준 통화 환율 변환기. 스왑으로 방향을 바꾼다.
@MainActor @Observable
final class ConverterViewModel {
    var amountText = ""
    let localCurrency: String
    let baseCurrency: String
    private(set) var isSwapped = false
    private(set) var table: RateTable?
    private(set) var errorMessage: String?

    init(localCurrency: String, baseCurrency: String) {
        self.localCurrency = localCurrency
        self.baseCurrency = baseCurrency
    }

    var fromCurrency: String { isSwapped ? baseCurrency : localCurrency }
    var toCurrency: String { isSwapped ? localCurrency : baseCurrency }

    var convertedAmount: Double? {
        guard let amount = Double(amountText),
              let rate = try? table?.rate(from: fromCurrency, to: toCurrency) else { return nil }
        return amount * rate
    }

    func swap() {
        isSwapped.toggle()
    }

    func load(using service: CurrencyService?, forceRefresh: Bool = false) async {
        guard let service else {
            errorMessage = "환율 서비스를 사용할 수 없어요."
            return
        }
        do {
            table = forceRefresh
                ? try await service.refresh(base: baseCurrency)
                : try await service.rates(base: baseCurrency)
            errorMessage = nil
        } catch {
            errorMessage = "환율을 불러오지 못했어요."
        }
    }
}
