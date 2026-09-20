import Foundation

public enum ExchangeRateAPIError: Error, Equatable {
    case apiError(String)
    case malformedResponse
}

/// ExchangeRate-API v6 `/latest/{base}` 응답.
struct ExchangeRateResponse: Decodable {
    let result: String
    let errorType: String?
    let baseCode: String?
    let timeLastUpdateUnix: TimeInterval?
    let conversionRates: [String: Double]?

    enum CodingKeys: String, CodingKey {
        case result
        case errorType = "error-type"
        case baseCode = "base_code"
        case timeLastUpdateUnix = "time_last_update_unix"
        case conversionRates = "conversion_rates"
    }

    func makeRateTable() throws -> RateTable {
        guard result == "success" else {
            throw ExchangeRateAPIError.apiError(errorType ?? result)
        }
        guard let baseCode, let timeLastUpdateUnix, let conversionRates else {
            throw ExchangeRateAPIError.malformedResponse
        }
        return RateTable(
            base: baseCode,
            rates: conversionRates,
            updatedAt: Date(timeIntervalSince1970: timeLastUpdateUnix)
        )
    }
}
