import Foundation
import SwiftData
import Testing
@testable import TravelBudgetCore

struct SettlementActorTests {
    @Test func settlesTripFromStore() async throws {
        let container = try makeModelContainer(inMemory: true)
        let context = ModelContext(container)

        let trip = Trip(name: "T", startDate: .now, endDate: .now, baseCurrency: "KRW", destinationCurrency: "USD", budget: 0)
        context.insert(trip)
        let people = ["A", "B", "C"].map(Participant.init(name:))
        for person in people {
            context.insert(person)
            person.trip = trip
        }
        let expense = Expense(title: "저녁", amount: 30000, currencyCode: "KRW", appliedRate: 1, baseAmount: 30000, category: .food, date: .now)
        context.insert(expense)
        expense.trip = trip
        expense.payer = people[0]
        expense.sharers = people
        try context.save()

        let table = RateTable(base: "KRW", rates: ["KRW": 1], updatedAt: .now)
        let transfers = try await SettlementActor(modelContainer: container)
            .settle(tripID: trip.persistentModelID, table: table)

        #expect(transfers.count == 2)
        #expect(transfers.allSatisfy { $0.to == people[0].id && abs($0.amount - 10000) < 1e-9 })
    }
}
