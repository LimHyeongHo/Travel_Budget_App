import SwiftData
import SwiftUI

/// 여행 중: 지출 기록, 영수증 스캔, 환율 변환기, 환율 변동 넛지.
struct DuringTripView: View {
    let trip: Trip
    @Environment(\.modelContext) private var context
    @Environment(\.currencyService) private var service
    @State private var stats = TripStatsViewModel()
    @State private var showingForm = false

    private var expenses: [Expense] { (trip.expenses ?? []).sorted { $0.date > $1.date } }

    var body: some View {
        List {
            if let nudge = stats.nudge {
                Section {
                    Label(nudge.message, systemImage: "chart.line.uptrend.xyaxis")
                }
            }
            Section("환율 변환기") { ConverterView(trip: trip) }
            Section("예산") {
                BudgetDonutChart(budget: trip.budget, spent: stats.spent, currency: trip.baseCurrency)
            }
            Section("지출") {
                ForEach(expenses) { ExpenseRow(expense: $0, baseCurrency: trip.baseCurrency) }
                    .onDelete { offsets in offsets.forEach { context.delete(expenses[$0]) } }
            }
        }
        .toolbar {
            Button("지출 추가", systemImage: "plus") { showingForm = true }
        }
        .sheet(isPresented: $showingForm) { ExpenseFormView(trip: trip) }
        .task(id: trip.expenses?.count) { await stats.refresh(trip: trip, service: service) }
    }
}

struct ExpenseRow: View {
    let expense: Expense
    let baseCurrency: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(expense.title.isEmpty ? expense.category.displayName : expense.title)
            HStack {
                Text(expense.amount.formatted(currency: expense.currencyCode))
                if let base = expense.baseAmount, expense.currencyCode != baseCurrency {
                    Text("≈ \(base.formatted(currency: baseCurrency))")
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
}
