import Foundation

struct CategoryTotal: Identifiable, Equatable {
    let category: ExpenseCategory
    /// 기준 통화 금액.
    let amount: Double

    var id: ExpenseCategory { category }
}

enum TripStats {
    /// 카테고리별 기준 통화 합계 (0원 제외, 큰 순서).
    static func categoryTotals(
        records: [ExpenseRecord],
        mode: RateMode,
        baseCurrency: String,
        table: RateTable
    ) throws -> [CategoryTotal] {
        var totals: [ExpenseCategory: Double] = [:]
        for record in records {
            totals[record.category, default: 0] += try record.baseAmount(mode: mode, baseCurrency: baseCurrency, table: table)
        }
        return totals
            .filter { $0.value > 0 }
            .map { CategoryTotal(category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    /// 결제 시점에 고정된 환율들의 금액 가중 평균. 고정된 기록이 없으면 nil.
    static func averageFixedRate(records: [ExpenseRecord], currency: String) -> Double? {
        let fixed = records.filter { $0.currencyCode == currency && $0.baseAmount != nil }
        let amount = fixed.reduce(0) { $0 + $1.amount }
        guard amount > 0 else { return nil }
        return fixed.reduce(0) { $0 + ($1.baseAmount ?? 0) } / amount
    }
}

/// 기록 시점 평균 환율 대비 현재 환율이 크게 움직였을 때의 안내.
struct RateNudge: Equatable {
    /// (현재 - 기준) / 기준
    let changeRatio: Double

    static func evaluate(current: Double, reference: Double, threshold: Double = 0.01) -> RateNudge? {
        guard reference > 0 else { return nil }
        let ratio = (current - reference) / reference
        return abs(ratio) >= threshold ? RateNudge(changeRatio: ratio) : nil
    }

    var message: String {
        let percent = String(format: "%.1f", abs(changeRatio) * 100)
        let direction = changeRatio < 0 ? "하락" : "상승"
        return "환율이 기록 시점 평균보다 \(percent)% \(direction)했어요."
    }
}
