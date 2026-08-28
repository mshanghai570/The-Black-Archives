import SwiftUI
import UniformTypeIdentifiers
import UIKit

/// Document picker that lets the user import a model from the iPhone's local
/// Files app. It accepts both individual weight files and whole model
/// directories (e.g. a `.mlmodelc` or `.mlpackage` folder), which the standard
/// single-file `fileImporter` cannot select.
///
/// The picker is presented from a real `UIViewController` with
/// `modalPresentationStyle = .fullScreen` rather than inside a SwiftUI
/// `.sheet`. `UIDocumentPickerViewController` hosted in a `.sheet` can drop
/// touches, making file selection appear broken.
struct LocalModelImporter: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onImport: ([URL]) -> Void
    var onCancel: () -> Void = {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> HostController {
        HostController(coordinator: context.coordinator)
    }

    func updateUIViewController(_ uiViewController: HostController, context: Context) {
        // Present the picker once the host controller is in the view hierarchy.
        uiViewController.presentPickerIfNeeded()
    }

    // MARK: - Host controller

    final class HostController: UIViewController {
        let coordinator: Coordinator
        private var hasPresented = false

        init(coordinator: Coordinator) {
            self.coordinator = coordinator
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) { fatalError() }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            presentPickerIfNeeded()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            // If the sheet is dismissed while the picker is still on screen
            // (e.g. swipe-to-dismiss), dismiss the picker to avoid orphaned
            // modal view controllers. Skip if the picker is already being
            // dismissed by the delegate callback.
            if let picker = presentedViewController as? UIDocumentPickerViewController, !picker.isBeingDismissed {
                dismiss(animated: false)
            }
        }

        func presentPickerIfNeeded() {
            guard !hasPresented else { return }
            hasPresented = true

            var contentTypes: [UTType] = [.folder, .item, .data]
            if let safetensorsType = UTType(filenameExtension: "safetensors") {
                contentTypes.append(safetensorsType)
            }
            if let ggufType = UTType(filenameExtension: "gguf") {
                contentTypes.append(ggufType)
            }
            if let mlmodelType = UTType(filenameExtension: "mlmodel") {
                contentTypes.append(mlmodelType)
            }
            if let mlpackageType = UTType(filenameExtension: "mlpackage") {
                contentTypes.append(mlpackageType)
            }
            if let mlmodelcType = UTType(filenameExtension: "mlmodelc") {
                contentTypes.append(mlmodelcType)
            }

            let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes, asCopy: true)
            picker.allowsMultipleSelection = true
            picker.delegate = coordinator
            picker.shouldShowFileExtensions = true
            picker.modalPresentationStyle = .fullScreen
            present(picker, animated: true)
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
        let parent: LocalModelImporter

        init(_ parent: LocalModelImporter) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            // Pass URLs through; the caller manages security-scoped access.
            guard !urls.isEmpty else {
                parent.onCancel()
                parent.isPresented = false
                return
            }
            controller.dismiss(animated: true) { [weak self] in
                guard let self else { return }
                self.parent.onImport(urls)
                self.parent.isPresented = false
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            controller.dismiss(animated: true) { [weak self] in
                self?.parent.onCancel()
                self?.parent.isPresented = false
            }
        }
    }
}
