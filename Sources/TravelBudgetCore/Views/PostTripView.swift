import SwiftData
import SwiftUI

/// 여행 후: 리뷰 작성, 다중 사용자 정산, 카테고리별 통계.
struct PostTripView: View {
    @Bindable var trip: Trip
    @Environment(\.modelContext) private var context
    @Environment(\.currencyService) private var service
    @State private var stats = TripStatsViewModel()
    @State private var settlement = SettlementViewModel()

    var body: some View {
        List {
            Section("여행은 어땠나요?") {
                TextEditor(text: $trip.reviewText).frame(minHeight: 100)
            }
            Section("정산") {
                Button("정산 계산") {
                    Task { await settlement.calculate(trip: trip, container: context.container, service: service) }
                }
                .disabled(settlement.isLoading)
                ForEach(settlement.transfers) { transfer in
                    LabeledContent("\(name(of: transfer.from)) → \(name(of: transfer.to))",
                                   value: transfer.amount.formatted(currency: trip.baseCurrency))
                }
                if let error = settlement.errorMessage {
                    Text(error).foregroundStyle(.red)
                }
            }
            Section("카테고리별 통계") {
                CategoryDashboardView(totals: stats.categoryTotals, currency: trip.baseCurrency)
            }
        }
        .task { await stats.refresh(trip: trip, service: service) }
    }

    private func name(of id: UUID) -> String {
        trip.participants?.first { $0.id == id }?.name ?? "?"
    }
}
