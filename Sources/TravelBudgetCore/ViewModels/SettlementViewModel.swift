import Foundation
import Observation
import SwiftData

@MainActor @Observable
final class SettlementViewModel {
    private(set) var transfers: [Transfer] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    /// `.atSettlement`이면 지금 시점의 최신 환율을 받아 적용한다. 받지 못하면 캐시로 대체한다.
    func calculate(trip: Trip, container: ModelContainer, service: CurrencyService?) async {
        guard let service else {
            errorMessage = "환율 서비스를 사용할 수 없어요."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let table: RateTable
            if trip.rateMode == .atSettlement, let fresh = try? await service.refresh(base: trip.baseCurrency) {
                table = fresh
            } else {
                table = try await service.rates(base: trip.baseCurrency)
            }
            transfers = try await SettlementActor(modelContainer: container)
                .settle(tripID: trip.persistentModelID, table: table)
            errorMessage = nil
        } catch {
            errorMessage = "정산을 계산하지 못했어요."
        }
    }
}
