import SwiftUI

/// 여행 시점(전/중/후)에 따라 홈 화면을 바꾼다.
struct HomeView: View {
    let trip: Trip

    var body: some View {
        Group {
            switch TripPhase.phase(start: trip.startDate, end: trip.endDate, now: .now) {
            case .pre: PreTripView(trip: trip)
            case .during: DuringTripView(trip: trip)
            case .post: PostTripView(trip: trip)
            }
        }
        .navigationTitle(trip.name)
    }
}
