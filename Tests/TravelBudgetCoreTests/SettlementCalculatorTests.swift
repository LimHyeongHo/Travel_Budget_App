import Foundation
import Testing
@testable import TravelBudgetCore

struct SettlementCalculatorTests {
    let a = UUID(), b = UUID(), c = UUID()
    let table = RateTable(base: "USD", rates: ["USD": 1, "KRW": 1000], updatedAt: Date(timeIntervalSince1970: 0))

    func record(_ amount: Double, _ currency: String = "KRW", fixedBase: Double? = nil, payer: UUID, sharers: [UUID]) -> ExpenseRecord {
        ExpenseRecord(amount: amount, currencyCode: currency, baseAmount: fixedBase, category: .food, payerID: payer, sharerIDs: sharers)
    }

    @Test func equalSplitOwedToPayer() throws {
        let transfers = try SettlementCalculator.settle(
            records: [record(30000, payer: a, sharers: [a, b, c])],
            mode: .atPayment, baseCurrency: "KRW", table: table
        )
        #expect(transfers.count == 2)
        #expect(Set(transfers.map(\.to)) == [a])
        #expect(Set(transfers.map(\.from)) == [b, c])
        for transfer in transfers { #expect(abs(transfer.amount - 10000) < 1e-9) }
    }

    @Test func mutualDebtsNetOut() throws {
        // A가 B와 나눠 20000, B가 A와 나눠 20000 결제 → 서로 상계되어 송금 없음.
        let transfers = try SettlementCalculator.settle(
            records: [record(20000, payer: a, sharers: [a, b]), record(20000, payer: b, sharers: [a, b])],
            mode: .atPayment, baseCurrency: "KRW", table: table
        )
        #expect(transfers.isEmpty)
    }

    @Test func fixedVersusLiveRates() throws {
        // USD 10, 결제 시점 환율 900원 고정 vs 정산 시점 환율 1000원.
        let records = [record(10, "USD", fixedBase: 9000, payer: a, sharers: [a, b])]
        let fixed = try SettlementCalculator.settle(records: records, mode: .atPayment, baseCurrency: "KRW", table: table)
        let live = try SettlementCalculator.settle(records: records, mode: .atSettlement, baseCurrency: "KRW", table: table)
        #expect(abs(fixed[0].amount - 4500) < 1e-9)
        #expect(abs(live[0].amount - 5000) < 1e-9)
    }

    @Test func missingFixedRateFallsBackToLiveRate() throws {
        let records = [record(10, "USD", fixedBase: nil, payer: a, sharers: [a, b])]
        let transfers = try SettlementCalculator.settle(records: records, mode: .atPayment, baseCurrency: "KRW", table: table)
        #expect(abs(transfers[0].amount - 5000) < 1e-9)
    }

    @Test func recordsWithoutPayerOrSharersAreSkipped() throws {
        let records = [
            ExpenseRecord(amount: 100, currencyCode: "KRW", baseAmount: nil, category: .food, payerID: nil, sharerIDs: [a]),
            record(100, payer: a, sharers: []),
        ]
        #expect(try SettlementCalculator.settle(records: records, mode: .atPayment, baseCurrency: "KRW", table: table).isEmpty)
    }

    @Test func unsupportedCurrencyThrows() {
        #expect(throws: CurrencyError.unsupportedCurrency("XXX")) {
            try SettlementCalculator.settle(
                records: [record(1, "XXX", payer: a, sharers: [a, b])],
                mode: .atSettlement, baseCurrency: "KRW", table: table
            )
        }
    }

    /// 임의의 지출 목록에서도 송금은 최대 N-1번이고, 적용하면 모든 잔액이 0이 된다.
    @Test(arguments: 1...30)
    func randomizedInvariants(seed: Int) throws {
        var rng = SplitMix64(seed: UInt64(seed))
        let people = (0..<Int.random(in: 2...8, using: &rng)).map { _ in UUID() }
        let records = (0..<Int.random(in: 1...25, using: &rng)).map { _ -> ExpenseRecord in
            let sharers = people.filter { _ in Bool.random(using: &rng) }
            return record(
                Double(Int.random(in: 1...500_000, using: &rng)),
                payer: people.randomElement(using: &rng)!,
                sharers: sharers.isEmpty ? [people[0]] : sharers
            )
        }

        var balances = try SettlementCalculator.netBalances(records: records, mode: .atPayment, baseCurrency: "KRW", table: table)
        let transfers = SettlementCalculator.transfers(from: balances)
        #expect(transfers.count <= max(people.count - 1, 0))

        for transfer in transfers {
            balances[transfer.from, default: 0] += transfer.amount
            balances[transfer.to, default: 0] -= transfer.amount
        }
        for balance in balances.values { #expect(abs(balance) < 0.01) }
    }
}

struct SplitMix64: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
