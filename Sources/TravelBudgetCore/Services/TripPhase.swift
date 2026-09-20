import Foundation

enum TripPhase: Equatable {
    case pre, during, post

    /// 시작일 0시 이전은 여행 전, 종료일 다음 날 0시부터는 여행 후.
    static func phase(start: Date, end: Date, now: Date, calendar: Calendar = .current) -> TripPhase {
        guard now >= calendar.startOfDay(for: start) else { return .pre }
        let endDay = calendar.startOfDay(for: end)
        let endExclusive = calendar.date(byAdding: .day, value: 1, to: endDay) ?? endDay
        return now < endExclusive ? .during : .post
    }
}
