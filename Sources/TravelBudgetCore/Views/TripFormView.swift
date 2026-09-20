import SwiftData
import SwiftUI

struct TripFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var baseCurrency = "KRW"
    @State private var destinationCurrency = "USD"
    @State private var budget = 0.0

    var body: some View {
        NavigationStack {
            Form {
                TextField("여행 이름", text: $name)
                DatePicker("출발", selection: $startDate, displayedComponents: .date)
                DatePicker("도착", selection: $endDate, in: startDate..., displayedComponents: .date)
                Picker("기준 통화", selection: $baseCurrency) {
                    ForEach(CommonCurrencies.codes, id: \.self, content: Text.init)
                }
                Picker("목적지 통화", selection: $destinationCurrency) {
                    ForEach(CommonCurrencies.codes, id: \.self, content: Text.init)
                }
                TextField("총 예산 (\(baseCurrency))", value: $budget, format: .number)
                #if os(iOS)
                    .keyboardType(.decimalPad)
                #endif
            }
            .navigationTitle("새 여행")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장", action: save).disabled(name.isEmpty)
                }
            }
        }
    }

    private func save() {
        let trip = Trip(
            name: name, startDate: startDate, endDate: endDate,
            baseCurrency: baseCurrency, destinationCurrency: destinationCurrency, budget: budget
        )
        context.insert(trip)
        let me = Participant(name: "나")
        context.insert(me)
        me.trip = trip
        dismiss()
    }
}
