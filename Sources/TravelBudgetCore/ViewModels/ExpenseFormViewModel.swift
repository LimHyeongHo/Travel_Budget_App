import CoreGraphics
import Foundation
import Observation
import SwiftData

@MainActor @Observable
final class ExpenseFormViewModel {
    var title = ""
    var amountText = ""
    var currencyCode: String
    var category: ExpenseCategory = .food
    var date = Date()
    var payerID: UUID?
    private(set) var sharerIDs: Set<UUID>
    private(set) var isSaving = false
    private(set) var isScanning = false
    var errorMessage: String?

    private let trip: Trip

    init(trip: Trip) {
        self.trip = trip
        self.currencyCode = trip.destinationCurrency
        let participants = trip.participants ?? []
        self.payerID = participants.first?.id
        self.sharerIDs = Set(participants.map(\.id))
    }

    var amount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "")).flatMap { $0 > 0 ? $0 : nil }
    }

    var canSave: Bool {
        amount != nil && payerID != nil && !sharerIDs.isEmpty
    }

    func setSharer(_ id: UUID, isOn: Bool) {
        if isOn { sharerIDs.insert(id) } else { sharerIDs.remove(id) }
    }

    /// 결제 시점 환율을 받아 기록에 고정한다. 환율을 얻지 못하면 고정값 없이 저장한다.
    func save(service: CurrencyService?, context: ModelContext) async -> Bool {
        guard let amount, canSave else { return false }
        isSaving = true
        defer { isSaving = false }

        var rate: Double?
        if currencyCode == trip.baseCurrency {
            rate = 1
        } else if let service, let table = try? await service.rates(base: trip.baseCurrency) {
            rate = try? table.rate(from: currencyCode, to: trip.baseCurrency)
        }

        let participants = trip.participants ?? []
        let expense = Expense(
            title: title,
            amount: amount,
            currencyCode: currencyCode,
            appliedRate: rate,
            baseAmount: rate.map { $0 * amount },
            category: category,
            date: date
        )
        context.insert(expense)
        expense.trip = trip
        expense.payer = participants.first { $0.id == payerID }
        expense.sharers = participants.filter { sharerIDs.contains($0.id) }
        do {
            try context.save()
            return true
        } catch {
            context.delete(expense)
            errorMessage = "저장하지 못했어요."
            return false
        }
    }

    /// 스캔한 영수증을 온디바이스로 인식·정형화해 폼을 채운다.
    func applyScan(_ images: [CGImage]) async {
        guard let image = images.first else { return }
        isScanning = true
        defer { isScanning = false }
        do {
            let text = try await ReceiptTextExtractor.text(from: image)
            guard let receipt = try await ReceiptParser.parseIfAvailable(text, preferredCurrency: trip.destinationCurrency) else {
                errorMessage = "이 기기에서는 Apple Intelligence 영수증 분석을 쓸 수 없어요."
                return
            }
            title = receipt.merchant
            amountText = String(receipt.amount)
            if let code = receipt.currencyCode { currencyCode = code }
            if let date = receipt.date { self.date = date }
        } catch {
            errorMessage = "영수증을 분석하지 못했어요."
        }
    }
}
