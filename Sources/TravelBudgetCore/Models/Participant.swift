import Foundation
import SwiftData

@Model
final class Participant {
    /// 정산 계산에서 참여자를 식별한다. (`.unique`는 CloudKit 때문에 쓰지 않는다)
    var id: UUID = UUID()
    var name: String = ""
    var trip: Trip?

    @Relationship(inverse: \Expense.payer)
    var paidExpenses: [Expense]?
    @Relationship(inverse: \Expense.sharers)
    var sharedExpenses: [Expense]?

    init(name: String) {
        self.name = name
    }
}
