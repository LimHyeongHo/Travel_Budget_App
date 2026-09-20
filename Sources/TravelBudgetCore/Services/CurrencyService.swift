import Foundation

/// ExchangeRate-API v6 를 async/await 로 감싼 환율 서비스.
/// `maxAge` 안의 캐시는 네트워크 없이 반환하고(호출량 제한 방어), 같은 기축 통화의 동시 요청은 하나로 합친다.
/// 네트워크가 실패하면 마지막 캐시로 동작한다.
public actor CurrencyService {
    private let apiKey: String
    private let cache: any RateCache
    private let session: URLSession
    private let maxAge: TimeInterval
    private let now: @Sendable () -> Date
    private var inFlight: [String: Task<RateTable, Error>] = [:]

    public init(
        apiKey: String,
        cache: any RateCache,
        session: URLSession = .shared,
        maxAge: TimeInterval = 6 * 3600,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.apiKey = apiKey
        self.cache = cache
        self.session = session
        self.maxAge = maxAge
        self.now = now
    }

    /// 캐시가 신선하면 캐시를, 아니면 새로 받아온다. 새로 받기 실패 시 오래된 캐시로 대체한다.
    public func rates(base: String) async throws -> RateTable {
        let base = try Self.normalized(base)
        let cached = try? cache.load(base: base)
        if let cached, now().timeIntervalSince(cached.fetchedAt) < maxAge {
            return cached.table
        }
        do {
            return try await refresh(base: base)
        } catch {
            if let cached { return cached.table }
            throw error
        }
    }

    /// 캐시를 무시하고 항상 네트워크에서 받아 캐시에 저장한다.
    public func refresh(base: String) async throws -> RateTable {
        let base = try Self.normalized(base)
        if let task = inFlight[base] { return try await task.value }
        let task = Task { try await self.fetch(base: base) }
        inFlight[base] = task
        defer { inFlight[base] = nil }
        return try await task.value
    }

    private func fetch(base: String) async throws -> RateTable {
        guard let url = URL(string: "https://v6.exchangerate-api.com/v6/\(apiKey)/latest/\(base)") else {
            throw ExchangeRateAPIError.malformedResponse
        }
        let (data, _) = try await session.data(from: url)
        let response: ExchangeRateResponse
        do {
            response = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
        } catch {
            throw ExchangeRateAPIError.malformedResponse
        }
        let table = try response.makeRateTable()
        // 캐시 저장 실패가 환율 조회 자체를 막지 않도록 무시한다.
        try? cache.save(CachedRates(table: table, fetchedAt: now()))
        return table
    }

    private static func normalized(_ code: String) throws -> String {
        let upper = code.uppercased()
        guard upper.count == 3, upper.allSatisfy({ $0.isASCII && $0.isLetter }) else {
            throw CurrencyError.unsupportedCurrency(code)
        }
        return upper
    }
}
