import SwiftData

@ModelActor
actor TripCurrencyReader {
    func baseCurrencies() throws -> Set<String> {
        Set(try modelContext.fetch(FetchDescriptor<Trip>()).map(\.baseCurrency))
    }
}

/// 저장된 여행들의 기준 통화 환율을 모두 새로 받는다. 백그라운드 갱신 작업에서 쓴다.
public func refreshStoredRates(container: ModelContainer, service: CurrencyService) async -> Bool {
    guard let bases = try? await TripCurrencyReader(modelContainer: container).baseCurrencies() else {
        return false
    }
    var succeeded = true
    for base in bases where (try? await service.refresh(base: base)) == nil {
        succeeded = false
    }
    return succeeded
}
