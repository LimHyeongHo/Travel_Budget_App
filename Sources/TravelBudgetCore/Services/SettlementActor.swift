import SwiftData

/// 정산 연산을 메인 스레드 밖에서 실행한다.
@ModelActor
actor SettlementActor {
    func settle(tripID: PersistentIdentifier, table: RateTable) throws -> [Transfer] {
        guard let trip = self[tripID, as: Trip.self] else { return [] }
        return try SettlementCalculator.settle(
            records: (trip.expenses ?? []).map(ExpenseRecord.init),
            mode: trip.rateMode,
            baseCurrency: trip.baseCurrency,
            table: table
        )
    }
}
