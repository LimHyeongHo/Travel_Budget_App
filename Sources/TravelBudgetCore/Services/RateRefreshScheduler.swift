#if os(iOS)
import BackgroundTasks
import Foundation

/// 주기적 환율 갱신. 앱 Info.plist의 `BGTaskSchedulerPermittedIdentifiers`에 `taskIdentifier`를 등록해야 한다.
public enum RateRefreshScheduler {
    public static let taskIdentifier = "com.travelbudget.rateRefresh"

    /// 앱 실행이 끝나기 전(`App.init` 등)에 한 번 호출한다.
    public static func register(refresh: @escaping @Sendable () async -> Bool) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            schedule()
            nonisolated(unsafe) let bgTask = task
            let work = Task { bgTask.setTaskCompleted(success: await refresh()) }
            bgTask.expirationHandler = { work.cancel() }
        }
    }

    /// 앱이 백그라운드로 갈 때마다 호출해 다음 갱신을 예약한다.
    public static func schedule(earliestIn interval: TimeInterval = 6 * 3600) {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)
        try? BGTaskScheduler.shared.submit(request)
    }
}
#endif
