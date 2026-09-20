import CoreGraphics
import Vision

struct RecognizedText: Equatable, Sendable {
    let text: String
    /// Vision 정규화 좌표 (원점: 좌하단).
    let box: CGRect
}

/// 같은 줄에 있는 텍스트 조각을 좌표 기준으로 병합해 위에서 아래, 왼쪽에서 오른쪽 순의 행으로 만든다.
enum ReceiptLineMerger {
    static func merge(_ items: [RecognizedText]) -> String {
        var lines: [[RecognizedText]] = []
        for item in items.sorted(by: { $0.box.midY > $1.box.midY }) {
            if let anchor = lines.last?.first,
               abs(anchor.box.midY - item.box.midY) < max(anchor.box.height, item.box.height) / 2 {
                lines[lines.count - 1].append(item)
            } else {
                lines.append([item])
            }
        }
        return lines
            .map { $0.sorted { $0.box.minX < $1.box.minX }.map(\.text).joined(separator: " ") }
            .joined(separator: "\n")
    }
}

enum ReceiptTextExtractor {
    /// 온디바이스 Vision 텍스트 인식. 외부 서버로 이미지를 보내지 않는다.
    static func text(from image: CGImage) async throws -> String {
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true
        try VNImageRequestHandler(cgImage: image).perform([request])
        let items = (request.results ?? []).compactMap { observation in
            observation.topCandidates(1).first.map { RecognizedText(text: $0.string, box: observation.boundingBox) }
        }
        return ReceiptLineMerger.merge(items)
    }
}
