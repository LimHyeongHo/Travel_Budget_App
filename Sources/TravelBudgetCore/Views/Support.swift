import SwiftUI

extension EnvironmentValues {
    @Entry var currencyService: CurrencyService? = nil
}

enum CommonCurrencies {
    static let codes = [
        "KRW", "USD", "JPY", "EUR", "GBP", "CNY", "THB", "VND",
        "AUD", "CAD", "SGD", "HKD", "TWD", "PHP", "CHF",
    ]

    /// 목록에 없는 통화(영수증 인식 결과 등)도 선택지에 남긴다.
    static func options(including code: String) -> [String] {
        codes.contains(code) ? codes : [code] + codes
    }
}

extension Double {
    func formatted(currency code: String) -> String {
        formatted(.currency(code: code).precision(.fractionLength(0...2)))
    }
}
