#if os(iOS)
import SwiftUI
import VisionKit

/// `VNDocumentCameraViewController`로 영수증 사각형을 자동 식별해 캡처한다.
struct ReceiptScannerView: UIViewControllerRepresentable {
    let onScan: @MainActor ([CGImage]) -> Void
    let onCancel: @MainActor () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onCancel: onCancel)
    }

    /// 델리게이트 프로토콜이 nonisolated라 메서드도 nonisolated로 두고, 항상 메인 스레드에서 호출되므로 메인 액터로 진입한다.
    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScan: @MainActor ([CGImage]) -> Void
        let onCancel: @MainActor () -> Void

        init(onScan: @escaping @MainActor ([CGImage]) -> Void, onCancel: @escaping @MainActor () -> Void) {
            self.onScan = onScan
            self.onCancel = onCancel
        }

        nonisolated func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            MainActor.assumeIsolated {
                onScan((0..<scan.pageCount).compactMap { scan.imageOfPage(at: $0).cgImage })
            }
        }

        nonisolated func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            MainActor.assumeIsolated { onCancel() }
        }

        nonisolated func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            MainActor.assumeIsolated { onCancel() }
        }
    }
}
#endif
