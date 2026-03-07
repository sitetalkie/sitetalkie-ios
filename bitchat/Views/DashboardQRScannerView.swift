//
// DashboardQRScannerView.swift
// bitchat
//
// QR code scanner for signing in to the SiteTalkie Dashboard.
// Scans a sitetalkie://auth deep link and routes it through
// the existing handleAuthDeepLink flow in BitchatApp.
//

import SwiftUI
import AVFoundation

#if os(iOS)
struct DashboardQRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scannedCode: String?
    @State private var cameraPermissionDenied = false

    private let backgroundColor = Color(red: 0.055, green: 0.063, blue: 0.071)
    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)
    private let labelText = Color(red: 0.541, green: 0.557, blue: 0.588)
    private let cardBackground = Color(red: 0.102, green: 0.110, blue: 0.125)

    var body: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()

                if cameraPermissionDenied {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48))
                            .foregroundColor(labelText)
                        Text("Camera Access Required")
                            .font(.bitchatSystem(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        Text("Open Settings and allow camera access to scan dashboard QR codes.")
                            .font(.bitchatSystem(size: 14))
                            .foregroundColor(labelText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .font(.bitchatSystem(size: 15, weight: .semibold))
                        .foregroundColor(amber)
                        .padding(.top, 8)
                    }
                } else {
                    VStack(spacing: 0) {
                        QRScannerRepresentable(onCodeScanned: handleScannedCode)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(24)

                        Text("Point your camera at the QR code on the dashboard login screen")
                            .font(.bitchatSystem(size: 14))
                            .foregroundColor(labelText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Scan Dashboard QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(amber)
                }
            }
            .onAppear(perform: checkCameraPermission)
        }
        .preferredColorScheme(.dark)
    }

    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraPermissionDenied = !granted
                }
            }
        default:
            cameraPermissionDenied = true
        }
    }

    private func handleScannedCode(_ code: String) {
        guard scannedCode == nil else { return } // Process only the first scan
        guard code.hasPrefix("sitetalkie://auth"),
              let url = URL(string: code) else { return }
        scannedCode = code
        // Route through the existing onOpenURL → handleAuthDeepLink flow
        UIApplication.shared.open(url)
        dismiss()
    }
}

// MARK: - AVFoundation QR Scanner

private struct QRScannerRepresentable: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerViewController {
        let vc = QRScannerViewController()
        vc.onCodeScanned = onCodeScanned
        return vc
    }

    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
}

private final class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else { return }

        captureSession.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(output) else { return }
        captureSession.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: captureSession)
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        previewLayer = preview

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              object.type == .qr,
              let value = object.stringValue else { return }
        captureSession.stopRunning()
        onCodeScanned?(value)
    }
}
#endif
