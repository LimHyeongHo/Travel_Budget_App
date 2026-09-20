import Foundation

/// 영수증의 통화 기호($, ¥, € 등)를 ISO 4217 코드로 매핑한다.
enum CurrencyCodeMapper {
    /// 기호 하나가 여러 통화를 뜻할 수 있어 후보를 우선순위 순으로 둔다.
    private static let candidates: [String: [String]] = [
        "$": ["USD", "CAD", "AUD", "NZD", "HKD", "SGD", "MXN"],
        "US$": ["USD"], "C$": ["CAD"], "A$": ["AUD"], "NZ$": ["NZD"],
        "HK$": ["HKD"], "S$": ["SGD"], "NT$": ["TWD"], "R$": ["BRL"],
        "¥": ["JPY", "CNY"], "￥": ["JPY", "CNY"], "円": ["JPY"], "元": ["CNY"],
        "₩": ["KRW"], "원": ["KRW"],
        "€": ["EUR"], "£": ["GBP"], "฿": ["THB"], "₫": ["VND"], "₹": ["INR"], "₱": ["PHP"],
    ]

    /// 3글자 ISO 코드는 그대로, 기호는 후보에서 고른다. `preferred`(예: 목적지 통화)가 후보에 있으면 우선한다.
    static func code(for symbol: String, preferred: String? = nil) -> String? {
        let trimmed = symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        let upper = trimmed.uppercased()
        if upper.count == 3, upper.allSatisfy({ $0.isASCII && $0.isLetter }) { return upper }
        guard let list = candidates[trimmed] ?? candidates[upper] else { return nil }
        if let preferred = preferred?.uppercased(), list.contains(preferred) { return preferred }
        return list[0]
    }
}
