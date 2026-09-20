import Foundation
import Testing
@testable import TravelBudgetCore

struct RateTableTests {
    let table = RateTable(
        base: "USD",
        rates: ["USD": 1, "KRW": 1400, "JPY": 150, "EUR": 0.5, "BAD": 0],
        updatedAt: Date(timeIntervalSince1970: 0)
    )

    @Test(arguments: [
        ("USD", "KRW", 1400.0),
        ("KRW", "USD", 1.0 / 1400.0),
        ("KRW", "JPY", 150.0 / 1400.0),
        ("JPY", "EUR", 0.5 / 150.0),
        ("USD", "USD", 1.0),
    ])
    func crossRate(from: String, to: String, expected: Double) throws {
        let rate = try table.rate(from: from, to: to)
        #expect(abs(rate - expected) < 1e-12)
    }

    @Test func unsupportedCurrency() {
        #expect(throws: CurrencyError.unsupportedCurrency("XXX")) {
            try table.rate(from: "USD", to: "XXX")
        }
        #expect(throws: CurrencyError.unsupportedCurrency("XXX")) {
            try table.rate(from: "XXX", to: "USD")
        }
    }

    @Test func zeroSourceRateIsInvalid() {
        #expect(throws: CurrencyError.invalidRate("BAD")) {
            try table.rate(from: "BAD", to: "USD")
        }
    }
}
