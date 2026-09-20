import Foundation
import Testing
@testable import TravelBudgetCore

final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            guard let handler = Self.handler else { throw URLError(.unknown) }
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

final class RequestCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    func increment() { lock.withLock { value += 1 } }
    var count: Int { lock.withLock { value } }
}

@Suite(.serialized)
struct CurrencyServiceTests {
    static let clock = Date(timeIntervalSince1970: 1_700_000_000)

    static func json(krw: Double) -> Data {
        Data(#"{"result":"success","time_last_update_unix":1700000000,"base_code":"USD","conversion_rates":{"USD":1,"KRW":\#(krw)}}"#.utf8)
    }

    static func respond(_ data: Data, counter: RequestCounter, delay: TimeInterval = 0) {
        StubURLProtocol.handler = { request in
            counter.increment()
            if delay > 0 { Thread.sleep(forTimeInterval: delay) }
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, data)
        }
    }

    static func fail(with code: URLError.Code, counter: RequestCounter) {
        StubURLProtocol.handler = { _ in
            counter.increment()
            throw URLError(code)
        }
    }

    func makeService(cachedKRW: Double? = nil, cachedAge: TimeInterval = 0) throws -> (CurrencyService, FileRateCache) {
        let cache = FileRateCache(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
        if let cachedKRW {
            let table = RateTable(base: "USD", rates: ["USD": 1, "KRW": cachedKRW], updatedAt: Self.clock)
            try cache.save(CachedRates(table: table, fetchedAt: Self.clock.addingTimeInterval(-cachedAge)))
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        let service = CurrencyService(
            apiKey: "KEY",
            cache: cache,
            session: URLSession(configuration: config),
            maxAge: 3600,
            now: { Self.clock }
        )
        return (service, cache)
    }

    @Test func freshCacheSkipsNetwork() async throws {
        let counter = RequestCounter()
        Self.respond(Self.json(krw: 9999), counter: counter)
        let (service, _) = try makeService(cachedKRW: 1400, cachedAge: 60)
        let table = try await service.rates(base: "usd")
        #expect(table.rates["KRW"] == 1400)
        #expect(counter.count == 0)
    }

    @Test func staleCacheIsRefreshedAndSaved() async throws {
        let counter = RequestCounter()
        Self.respond(Self.json(krw: 1500), counter: counter)
        let (service, cache) = try makeService(cachedKRW: 1400, cachedAge: 7200)
        let table = try await service.rates(base: "USD")
        #expect(table.rates["KRW"] == 1500)
        #expect(counter.count == 1)
        #expect(try cache.load(base: "USD")?.table.rates["KRW"] == 1500)
        #expect(try cache.load(base: "USD")?.fetchedAt == Self.clock)
    }

    @Test(arguments: [URLError.Code.notConnectedToInternet, .timedOut, .networkConnectionLost])
    func networkFailureFallsBackToStaleCache(code: URLError.Code) async throws {
        let counter = RequestCounter()
        Self.fail(with: code, counter: counter)
        let (service, _) = try makeService(cachedKRW: 1400, cachedAge: 7200)
        let table = try await service.rates(base: "USD")
        #expect(table.rates["KRW"] == 1400)
        #expect(counter.count == 1)
    }

    @Test(arguments: [URLError.Code.notConnectedToInternet, .timedOut, .networkConnectionLost])
    func networkFailureWithoutCacheThrows(code: URLError.Code) async throws {
        let counter = RequestCounter()
        Self.fail(with: code, counter: counter)
        let (service, _) = try makeService()
        await #expect(throws: URLError.self) {
            try await service.rates(base: "USD")
        }
    }

    @Test func apiErrorFallsBackToCacheOrThrows() async throws {
        let counter = RequestCounter()
        Self.respond(Data(#"{"result":"error","error-type":"quota-reached"}"#.utf8), counter: counter)

        let (withCache, _) = try makeService(cachedKRW: 1400, cachedAge: 7200)
        #expect(try await withCache.rates(base: "USD").rates["KRW"] == 1400)

        let (withoutCache, _) = try makeService()
        await #expect(throws: ExchangeRateAPIError.apiError("quota-reached")) {
            try await withoutCache.rates(base: "USD")
        }
    }

    @Test func garbageResponseIsMalformed() async throws {
        let counter = RequestCounter()
        Self.respond(Data("not json".utf8), counter: counter)
        let (service, _) = try makeService()
        await #expect(throws: ExchangeRateAPIError.malformedResponse) {
            try await service.rates(base: "USD")
        }
    }

    @Test func concurrentRefreshesShareOneRequest() async throws {
        let counter = RequestCounter()
        Self.respond(Self.json(krw: 1500), counter: counter, delay: 0.3)
        let (service, _) = try makeService()
        try await withThrowingTaskGroup(of: RateTable.self) { group in
            for _ in 0..<5 { group.addTask { try await service.refresh(base: "USD") } }
            for try await table in group { #expect(table.rates["KRW"] == 1500) }
        }
        #expect(counter.count == 1)
    }

    @Test(arguments: ["", "US", "USDX", "U$D", "한국원"])
    func invalidBaseIsRejected(base: String) async throws {
        let (service, _) = try makeService()
        await #expect(throws: CurrencyError.unsupportedCurrency(base)) {
            try await service.rates(base: base)
        }
    }
}
