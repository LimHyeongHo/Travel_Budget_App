import Charts
import SwiftUI

/// 예산 대비 지출 도넛 차트.
struct BudgetDonutChart: View {
    let budget: Double
    let spent: Double
    let currency: String

    private var slices: [(label: String, amount: Double)] {
        [("지출", spent), ("남은 예산", max(budget - spent, 0))].filter { $0.1 > 0 }
    }

    var body: some View {
        VStack {
            Chart(slices, id: \.label) { slice in
                SectorMark(angle: .value("금액", slice.amount), innerRadius: .ratio(0.6))
                    .foregroundStyle(by: .value("구분", slice.label))
            }
            .frame(height: 180)
            Text("\(spent.formatted(currency: currency)) / \(budget.formatted(currency: currency))")
                .font(.footnote)
                .foregroundStyle(spent > budget && budget > 0 ? .red : .secondary)
        }
    }
}

/// 카테고리별 지출 도넛 차트와 목록.
struct CategoryDashboardView: View {
    let totals: [CategoryTotal]
    let currency: String

    var body: some View {
        if totals.isEmpty {
            Text("지출 내역이 없어요").foregroundStyle(.secondary)
        } else {
            Chart(totals) { total in
                SectorMark(angle: .value("금액", total.amount), innerRadius: .ratio(0.6))
                    .foregroundStyle(by: .value("카테고리", total.category.displayName))
            }
            .frame(height: 180)
            ForEach(totals) { total in
                LabeledContent(total.category.displayName, value: total.amount.formatted(currency: currency))
            }
        }
    }
}
