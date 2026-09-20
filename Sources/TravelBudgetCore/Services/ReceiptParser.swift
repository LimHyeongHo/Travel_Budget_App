import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct ReceiptData: Equatable, Sendable {
    let merchant: String
    let date: Date?
    let amount: Double
    let currencyCode: String?

    /// 모델이 돌려준 원문 값을 앱 값으로 정형화한다. 날짜는 `yyyy-MM-dd`, 통화는 기호 또는 코드.
    init(merchant: String, dateString: String, amount: Double, currencySymbol: String, preferredCurrency: String?) {
        self.merchant = merchant
        self.amount = amount
        self.currencyCode = CurrencyCodeMapper.code(for: currencySymbol, preferred: preferredCurrency)
        let parts = dateString.split(separator: "-").compactMap { Int($0) }
        if parts.count == 3 {
            self.date = Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
        } else {
            self.date = nil
        }
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, macOS 26.0, *)
@Generable
struct GeneratedReceipt {
    @Guide(description: "상호명")
    var merchant: String
    @Guide(description: "결제 날짜, yyyy-MM-dd 형식. 알 수 없으면 빈 문자열")
    var date: String
    @Guide(description: "총 결제 금액. 소계나 세금이 아닌 합계이며 숫자만")
    var totalAmount: Double
    @Guide(description: "영수증에 인쇄된 통화 기호 또는 ISO 4217 코드를 그대로. 없으면 빈 문자열")
    var currencySymbol: String
}
#endif

enum ReceiptParser {
    /// Apple Intelligence(온디바이스)로 영수증 텍스트를 정형화한다. 지원되지 않는 기기면 nil.
    static func parseIfAvailable(_ text: String, preferredCurrency: String?) async throws -> ReceiptData? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            guard SystemLanguageModel.default.isAvailable else { return nil }
            let session = LanguageModelSession(
                instructions: "영수증 OCR 텍스트에서 상호명, 날짜, 총 결제 금액, 통화 기호를 추출한다."
            )
            let generated = try await session.respond(to: text, generating: GeneratedReceipt.self).content
            return ReceiptData(
                merchant: generated.merchant,
                dateString: generated.date,
                amount: generated.totalAmount,
                currencySymbol: generated.currencySymbol,
                preferredCurrency: preferredCurrency
            )
        }
        #endif
        return nil
    }
}
