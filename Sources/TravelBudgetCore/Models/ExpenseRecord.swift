import Foundation

/// 정산·통계 계산용 값 타입. SwiftData 모델과 분리해 액터 경계를 안전하게 넘긴다.
struct ExpenseRecord: Sendable, Equatable {
    var amount: Double
    var currencyCode: String
    var baseAmount: Double?
    var category: ExpenseCategory
    var payerID: UUID?
    var sharerIDs: [UUID]

    /// 기준 통화로 전처리한 금액.
    /// `.atPayment`이면 기록에 고정된 금액을 쓰고, 고정값이 없거나 `.atSettlement`이면 `table` 환율을 쓴다.
    func baseAmount(mode: RateMode, baseCurrency: String, table: RateTable) throws -> Double {
        if currencyCode == baseCurrency { return amount }
        if mode == .atPayment, let baseAmount { return baseAmount }
        return amount * (try table.rate(from: currencyCode, to: baseCurrency))
    }
}

extension ExpenseRecord {
    init(_ expense: Expense) {
        self.init(
            amount: expense.amount,
            currencyCode: expense.currencyCode,
            baseAmount: expense.baseAmount,
            category: expense.category,
            payerID: expense.payer?.id,
            sharerIDs: (expense.sharers ?? []).map(\.id)
        )
    }
}
