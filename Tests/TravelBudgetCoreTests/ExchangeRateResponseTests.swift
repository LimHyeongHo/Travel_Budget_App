import Foundation
import Testing
@testable import TravelBudgetCore

struct ExchangeRateResponseTests {
    private func decode(_ json: String) throws -> ExchangeRateResponse {
        try JSONDecoder().decode(ExchangeRateResponse.self, from: Data(json.utf8))
    }

    @Test func successResponseBecomesRateTable() throws {
        let response = try decode("""
        {"result":"success","time_last_update_unix":1700000000,
         "base_code":"USD","conversion_rates":{"USD":1,"KRW":1400.5}}
        """)
        let table = try response.makeRateTable()
        #expect(table.base == "USD")
        #expect(table.rates["KRW"] == 1400.5)
        #expect(table.updatedAt == Date(timeIntervalSince1970: 1_700_000_000))
    }

    @Test(arguments: ["invalid-key", "quota-reached", "unsupported-code"])
    func errorResponseThrowsApiError(errorType: String) throws {
        let response = try decode(#"{"result":"error","error-type":"\#(errorType)"}"#)
        #expect(throws: ExchangeRateAPIError.apiError(errorType)) {
            try response.makeRateTable()
        }
    }

    @Test func successWithoutRatesIsMalformed() throws {
        let response = try decode(#"{"result":"success","base_code":"USD"}"#)
        #expect(throws: ExchangeRateAPIError.malformedResponse) {
            try response.makeRateTable()
        }
    }
}
