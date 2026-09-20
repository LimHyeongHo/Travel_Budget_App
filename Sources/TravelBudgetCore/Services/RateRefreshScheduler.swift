#if os(iOS)
import BackgroundTasks
import Foundation

/// `BGTask`는 Sendable이 아니지만 `setTaskCompleted`는 어느 스레드에서 호출해도 되므로 상자로 감싸 넘긴다.
private struct UncheckedSendable<T>: @unchecked Sendable {
    let value: T
}

/// 주기적 환율 갱신. 앱 Info.plist의 `BGTaskSchedulerPermittedIdentifiers`에 `taskIdentifier`를 등록해야 한다.
public enum RateRefreshScheduler {
    public static let taskIdentifier = "com.travelbudget.rateRefresh"

    /// 앱 실행이 끝나기 전(`App.init` 등)에 한 번 호출한다.
    public static func register(refresh: @escaping @Sendable () async -> Bool) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            schedule()
            let box = UncheckedSendable(value: task)
            let work = Task { box.value.setTaskCompleted(success: await refresh()) }
            task.expirationHandler = { work.cancel() }
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
