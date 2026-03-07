//
// DocumentPickerView.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

#if os(iOS)
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Result returned when a document is picked
struct PickedDocument {
    let url: URL
    let name: String
    let size: Int64
}

/// SwiftUI wrapper for UIDocumentPickerViewController
struct DocumentPickerView: UIViewControllerRepresentable {
    let completion: (PickedDocument?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let supportedTypes: [UTType] = [
            .pdf,
            .plainText,
            UTType("org.openxmlformats.wordprocessingml.document") ?? .data, // .docx
            .data // fallback for other document types
        ]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let completion: (PickedDocument?) -> Void

        init(completion: @escaping (PickedDocument?) -> Void) {
            self.completion = completion
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                completion(nil)
                return
            }

            let name = url.lastPathComponent
            let size: Int64
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let fileSize = attrs[.size] as? Int64 {
                size = fileSize
            } else {
                size = 0
            }

            completion(PickedDocument(url: url, name: name, size: size))
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            completion(nil)
        }
    }
}
#endif
