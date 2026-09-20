import Foundation
import Testing
@testable import TravelBudgetCore

struct TripPhaseTests {
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul")!
        return calendar
    }

    func date(_ day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 5, day: day, hour: hour))!
    }

    @Test(arguments: [
        (9, 23, TripPhase.pre),
        (10, 0, .during),
        (12, 12, .during),
        (14, 23, .during), // 종료일은 하루 종일 여행 중
        (15, 0, .post),
    ])
    func phaseByDate(day: Int, hour: Int, expected: TripPhase) {
        let phase = TripPhase.phase(start: date(10), end: date(14), now: date(day, hour: hour), calendar: calendar)
        #expect(phase == expected)
    }
}

struct TripStatsTests {
    let table = RateTable(base: "USD", rates: ["USD": 1, "KRW": 1000], updatedAt: Date(timeIntervalSince1970: 0))

    func record(_ amount: Double, _ currency: String, fixed: Double?, _ category: ExpenseCategory) -> ExpenseRecord {
        ExpenseRecord(amount: amount, currencyCode: currency, baseAmount: fixed, category: category, payerID: nil, sharerIDs: [])
    }

    @Test func categoryTotalsAreSortedAndConverted() throws {
        let records = [
            record(10000, "KRW", fixed: nil, .food),
            record(10, "USD", fixed: 9000, .food),
            record(50, "USD", fixed: nil, .lodging),
        ]
        let totals = try TripStats.categoryTotals(records: records, mode: .atPayment, baseCurrency: "KRW", table: table)
        #expect(totals == [CategoryTotal(category: .lodging, amount: 50000), CategoryTotal(category: .food, amount: 19000)])
    }

    @Test func averageFixedRateIsAmountWeighted() {
        let records = [
            record(10, "USD", fixed: 9000, .food),  // 900
            record(30, "USD", fixed: 33000, .food), // 1100
            record(99, "USD", fixed: nil, .food),   // 고정값 없음: 제외
            record(5, "JPY", fixed: 50, .food),     // 다른 통화: 제외
        ]
        #expect(TripStats.averageFixedRate(records: records, currency: "USD") == 42000.0 / 40.0)
        #expect(TripStats.averageFixedRate(records: records, currency: "EUR") == nil)
    }
}

struct RateNudgeTests {
    @Test func belowThresholdIsNil() {
        #expect(RateNudge.evaluate(current: 1005, reference: 1000) == nil)
    }

    @Test(arguments: [(1100.0, "상승"), (900.0, "하락")])
    func reportsDirection(current: Double, word: String) throws {
        let nudge = try #require(RateNudge.evaluate(current: current, reference: 1000))
        #expect(nudge.message.contains(word))
        #expect(nudge.message.contains("10.0%"))
    }

    @Test func invalidReferenceIsNil() {
        #expect(RateNudge.evaluate(current: 1, reference: 0) == nil)
    }
}
