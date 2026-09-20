import CoreGraphics
import Foundation
import Testing
@testable import TravelBudgetCore

struct CurrencyCodeMapperTests {
    @Test(arguments: [
        ("$", nil, "USD"), ("$", "CAD", "CAD"), ("$", "KRW", "USD"),
        ("¥", nil, "JPY"), ("¥", "CNY", "CNY"), ("￥", nil, "JPY"),
        ("₩", nil, "KRW"), ("€", nil, "EUR"), ("£", nil, "GBP"),
        ("US$", nil, "USD"), (" NT$ ", nil, "TWD"), ("krw", nil, "KRW"), ("EUR", nil, "EUR"),
    ] as [(String, String?, String)])
    func mapsSymbols(symbol: String, preferred: String?, expected: String) {
        #expect(CurrencyCodeMapper.code(for: symbol, preferred: preferred) == expected)
    }

    @Test(arguments: ["", "?", "abcd", "12"])
    func unknownSymbolIsNil(symbol: String) {
        #expect(CurrencyCodeMapper.code(for: symbol) == nil)
    }
}

struct ReceiptLineMergerTests {
    private func item(_ text: String, x: Double, y: Double) -> RecognizedText {
        RecognizedText(text: text, box: CGRect(x: x, y: y, width: 0.2, height: 0.04))
    }

    @Test func mergesFragmentsIntoOrderedLines() {
        let items = [
            item("3,500", x: 0.7, y: 0.50),
            item("TOTAL", x: 0.1, y: 0.10),
            item("Coffee", x: 0.1, y: 0.501),
            item("7,000", x: 0.7, y: 0.102),
            item("Cafe Blue", x: 0.3, y: 0.90),
        ]
        #expect(ReceiptLineMerger.merge(items) == "Cafe Blue\nCoffee 3,500\nTOTAL 7,000")
    }

    @Test func emptyInputIsEmpty() {
        #expect(ReceiptLineMerger.merge([]) == "")
    }
}

struct ReceiptDataTests {
    @Test func normalizesModelOutput() {
        let data = ReceiptData(merchant: "Cafe", dateString: "2026-03-05", amount: 12.5, currencySymbol: "$", preferredCurrency: "CAD")
        #expect(data.currencyCode == "CAD")
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: data.date!)
        #expect(parts.year == 2026 && parts.month == 3 && parts.day == 5)
    }

    @Test(arguments: ["", "unknown", "2026/03/05"])
    func badDateBecomesNil(dateString: String) {
        #expect(ReceiptData(merchant: "", dateString: dateString, amount: 1, currencySymbol: "€", preferredCurrency: nil).date == nil)
    }
}
