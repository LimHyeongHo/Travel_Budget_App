import Collections
import Foundation

struct Transfer: Equatable, Sendable, Identifiable {
    let from: UUID
    let to: UUID
    let amount: Double

    var id: String { "\(from)-\(to)" }
}

/// 기준 통화 순 잔액을 구하고, 힙 기반 탐욕 상계로 송금 횟수를 최소화(최대 N-1번)한다.
enum SettlementCalculator {
    /// 기준 통화 단위의 이 값 이하 잔액은 정산 대상에서 제외한다.
    static let epsilon = 0.005

    /// Net_Balance(i) = Sum(받을 돈) - Sum(낼 돈). 결제자가 없거나 분담자가 없는 기록은 건너뛴다.
    static func netBalances(
        records: [ExpenseRecord],
        mode: RateMode,
        baseCurrency: String,
        table: RateTable
    ) throws -> [UUID: Double] {
        var balances: [UUID: Double] = [:]
        for record in records {
            guard let payer = record.payerID, !record.sharerIDs.isEmpty else { continue }
            let base = try record.baseAmount(mode: mode, baseCurrency: baseCurrency, table: table)
            balances[payer, default: 0] += base
            let share = base / Double(record.sharerIDs.count)
            for sharer in record.sharerIDs {
                balances[sharer, default: 0] -= share
            }
        }
        return balances
    }

    static func transfers(from balances: [UUID: Double]) -> [Transfer] {
        var creditors = Heap<Entry>()
        var debtors = Heap<Entry>()
        for (id, balance) in balances {
            if balance > epsilon {
                creditors.insert(Entry(id: id, amount: balance))
            } else if balance < -epsilon {
                debtors.insert(Entry(id: id, amount: -balance))
            }
        }

        var result: [Transfer] = []
        while let creditor = creditors.popMax(), let debtor = debtors.popMax() {
            let amount = min(creditor.amount, debtor.amount)
            result.append(Transfer(from: debtor.id, to: creditor.id, amount: amount))
            let creditorLeft = creditor.amount - amount
            let debtorLeft = debtor.amount - amount
            if creditorLeft > epsilon { creditors.insert(Entry(id: creditor.id, amount: creditorLeft)) }
            if debtorLeft > epsilon { debtors.insert(Entry(id: debtor.id, amount: debtorLeft)) }
        }
        return result
    }

    static func settle(
        records: [ExpenseRecord],
        mode: RateMode,
        baseCurrency: String,
        table: RateTable
    ) throws -> [Transfer] {
        transfers(from: try netBalances(records: records, mode: mode, baseCurrency: baseCurrency, table: table))
    }

    /// 금액이 큰 쪽이 먼저 나온다. 동률은 id로 갈라 결과를 결정적으로 만든다.
    private struct Entry: Comparable {
        let id: UUID
        let amount: Double

        static func < (lhs: Entry, rhs: Entry) -> Bool {
            lhs.amount != rhs.amount ? lhs.amount < rhs.amount : lhs.id.uuidString < rhs.id.uuidString
        }
    }
}
