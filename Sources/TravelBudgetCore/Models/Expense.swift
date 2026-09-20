import Foundation
import SwiftData

enum ExpenseCategory: String, CaseIterable, Sendable {
    case food, transport, lodging, shopping, activity, other

    var displayName: String {
        switch self {
        case .food: "식비"
        case .transport: "교통"
        case .lodging: "숙박"
        case .shopping: "쇼핑"
        case .activity: "액티비티"
        case .other: "기타"
        }
    }
}

@Model
final class Expense {
    var title: String = ""
    /// 결제 금액 (`currencyCode` 통화 기준).
    var amount: Double = 0
    var currencyCode: String = ""
    /// 결제 시점에 고정한 환율: 1 `currencyCode` = `appliedRate` 기준 통화. 환율을 얻지 못했으면 nil.
    var appliedRate: Double?
    /// 결제 시점 환율로 환산한 기준 통화 금액.
    var baseAmount: Double?
    var categoryRaw: String = ExpenseCategory.other.rawValue
    var date: Date = Date()

    var trip: Trip?
    var payer: Participant?
    var sharers: [Participant]?

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        title: String,
        amount: Double,
        currencyCode: String,
        appliedRate: Double?,
        baseAmount: Double?,
        category: ExpenseCategory,
        date: Date
    ) {
        self.title = title
        self.amount = amount
        self.currencyCode = currencyCode
        self.appliedRate = appliedRate
        self.baseAmount = baseAmount
        self.categoryRaw = category.rawValue
        self.date = date
    }
}
