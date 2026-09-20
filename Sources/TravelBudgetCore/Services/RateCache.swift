import Foundation

public struct CachedRates: Codable, Equatable, Sendable {
    public let table: RateTable
    public let fetchedAt: Date

    public init(table: RateTable, fetchedAt: Date) {
        self.table = table
        self.fetchedAt = fetchedAt
    }
}

/// 오프라인 구동을 위한 환율 영구 캐시.
public protocol RateCache: Sendable {
    func load(base: String) throws -> CachedRates?
    func save(_ cached: CachedRates) throws
}

public struct FileRateCache: RateCache {
    private let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public static var `default`: FileRateCache {
        FileRateCache(directory: URL.applicationSupportDirectory.appending(path: "rates"))
    }

    public func load(base: String) throws -> CachedRates? {
        let url = fileURL(base: base)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try JSONDecoder().decode(CachedRates.self, from: Data(contentsOf: url))
    }

    public func save(_ cached: CachedRates) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(cached).write(to: fileURL(base: cached.table.base), options: .atomic)
    }

    private func fileURL(base: String) -> URL {
        directory.appending(path: "rates-\(base).json")
    }
}
