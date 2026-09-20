import Foundation
import Observation

@MainActor @Observable
final class TripStatsViewModel {
    private(set) var categoryTotals: [CategoryTotal] = []
    private(set) var spent: Double = 0
    private(set) var nudge: RateNudge?
    private(set) var errorMessage: String?

    func refresh(trip: Trip, service: CurrencyService?) async {
        guard let service else {
            errorMessage = "환율 서비스를 사용할 수 없어요."
            return
        }
        let records = (trip.expenses ?? []).map(ExpenseRecord.init)
        do {
            let table = try await service.rates(base: trip.baseCurrency)
            categoryTotals = try TripStats.categoryTotals(
                records: records, mode: trip.rateMode, baseCurrency: trip.baseCurrency, table: table
            )
            spent = categoryTotals.reduce(0) { $0 + $1.amount }
            if let reference = TripStats.averageFixedRate(records: records, currency: trip.destinationCurrency) {
                nudge = RateNudge.evaluate(
                    current: try table.rate(from: trip.destinationCurrency, to: trip.baseCurrency),
                    reference: reference
                )
            } else {
                nudge = nil
            }
            errorMessage = nil
        } catch {
            errorMessage = "통계를 계산하지 못했어요."
        }
    }
}
