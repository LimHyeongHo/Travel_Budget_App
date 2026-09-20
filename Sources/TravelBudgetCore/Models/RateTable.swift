import Foundation

public enum CurrencyError: Error, Equatable {
    case unsupportedCurrency(String)
    case invalidRate(String)
}

/// 기축 통화(base) 기준 환율표. 제3국 통화 간 교차 환율은 여기서 계산한다.
public struct RateTable: Codable, Equatable, Sendable {
    public let base: String
    public let rates: [String: Double]
    public let updatedAt: Date

    public init(base: String, rates: [String: Double], updatedAt: Date) {
        self.base = base
        self.rates = rates
        self.updatedAt = updatedAt
    }

    /// `from` 통화 1단위가 `to` 통화 몇 단위인지 반환한다.
    public func rate(from: String, to: String) throws -> Double {
        guard let fromRate = rates[from] else { throw CurrencyError.unsupportedCurrency(from) }
        guard let toRate = rates[to] else { throw CurrencyError.unsupportedCurrency(to) }
        guard fromRate > 0 else { throw CurrencyError.invalidRate(from) }
        return toRate / fromRate
    }
}
