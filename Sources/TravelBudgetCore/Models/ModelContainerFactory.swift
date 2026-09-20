import SwiftData

/// 앱과 테스트가 공유하는 컨테이너 생성 함수. `cloudKit`을 켜려면 앱 타깃에 iCloud/CloudKit capability가 필요하다.
public func makeModelContainer(inMemory: Bool = false, cloudKit: Bool = false) throws -> ModelContainer {
    let configuration = ModelConfiguration(
        isStoredInMemoryOnly: inMemory,
        cloudKitDatabase: cloudKit ? .automatic : .none
    )
    return try ModelContainer(
        for: Trip.self, Participant.self, Expense.self,
        configurations: configuration
    )
}
