import SwiftData
import SwiftUI

/// 여행 전: 예산과 목적지 통화 환율 설정.
struct PreTripView: View {
    @Bindable var trip: Trip
    @Environment(\.modelContext) private var context
    @State private var newName = ""

    private var participants: [Participant] { trip.participants ?? [] }

    var body: some View {
        Form {
            Section("예산") {
                TextField("총 예산 (\(trip.baseCurrency))", value: $trip.budget, format: .number)
                #if os(iOS)
                    .keyboardType(.decimalPad)
                #endif
            }
            Section("환율") {
                Picker("목적지 통화", selection: $trip.destinationCurrency) {
                    ForEach(CommonCurrencies.options(including: trip.destinationCurrency), id: \.self, content: Text.init)
                }
                Picker("환산 방식", selection: $trip.rateMode) {
                    ForEach(RateMode.allCases, id: \.self) { Text($0.displayName) }
                }
                ConverterView(trip: trip).id(trip.destinationCurrency)
            }
            Section("참여자") {
                ForEach(participants) { Text($0.name) }
                    .onDelete { offsets in offsets.forEach { context.delete(participants[$0]) } }
                HStack {
                    TextField("이름", text: $newName)
                    Button("추가", action: addParticipant).disabled(newName.isEmpty)
                }
            }
        }
    }

    private func addParticipant() {
        let participant = Participant(name: newName)
        context.insert(participant)
        participant.trip = trip
        newName = ""
    }
}
