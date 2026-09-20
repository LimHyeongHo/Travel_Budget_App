import Foundation
import SwiftData

enum RateMode: String, CaseIterable, Sendable {
    /// 결제 시점 환율을 기록에 영구 고정한다.
    case atPayment
    /// 정산을 실행하는 순간의 최신 환율을 일괄 적용한다.
    case atSettlement

    var displayName: String {
        switch self {
        case .atPayment: "결제 시점 고정"
        case .atSettlement: "정산 시점 실시간"
        }
    }
}

// CloudKit 제약: @Attribute(.unique) 금지, 모든 속성은 기본값/옵셔널, 관계는 옵셔널 + 역방향 명시.
@Model
final class Trip {
    var name: String = ""
    var startDate: Date = Date()
    var endDate: Date = Date()
    var baseCurrency: String = "KRW"
    var destinationCurrency: String = "USD"
    /// 기준 통화 단위의 총 예산.
    var budget: Double = 0
    var rateModeRaw: String = RateMode.atPayment.rawValue
    var reviewText: String = ""

    @Relationship(deleteRule: .cascade, inverse: \Expense.trip)
    var expenses: [Expense]?
    @Relationship(deleteRule: .cascade, inverse: \Participant.trip)
    var participants: [Participant]?

    var rateMode: RateMode {
        get { RateMode(rawValue: rateModeRaw) ?? .atPayment }
        set { rateModeRaw = newValue.rawValue }
    }

    init(name: String, startDate: Date, endDate: Date, baseCurrency: String, destinationCurrency: String, budget: Double) {
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.baseCurrency = baseCurrency
        self.destinationCurrency = destinationCurrency
        self.budget = budget
    }
}
