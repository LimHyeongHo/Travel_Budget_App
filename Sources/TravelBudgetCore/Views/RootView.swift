import SwiftData
import SwiftUI

public struct RootView: View {
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]
    @State private var showingNewTrip = false
    private let currencyService: CurrencyService

    public init(currencyService: CurrencyService) {
        self.currencyService = currencyService
    }

    public var body: some View {
        NavigationStack {
            Group {
                if let trip = trips.first {
                    HomeView(trip: trip)
                } else {
                    ContentUnavailableView {
                        Label("여행이 없어요", systemImage: "airplane")
                    } actions: {
                        Button("새 여행 만들기") { showingNewTrip = true }
                    }
                }
            }
            .toolbar {
                Button("새 여행", systemImage: "plus") { showingNewTrip = true }
            }
            .sheet(isPresented: $showingNewTrip) { TripFormView() }
        }
        .environment(\.currencyService, currencyService)
    }
}
