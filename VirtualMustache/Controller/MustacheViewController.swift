//
//  MustacheViewController.swift
//  VirtualMustache
//
//  Created by yuzai on 11/13/24.
//

import UIKit
import ARKit
import CoreData
import ReplayKit
import AVFoundation
import SwiftUI
import Photos
import Alamofire


class MustacheViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    var dataSource = ["Mustache_1", "Mustache_2", "Mustache_3", "Mustache_4", "Mustache_5"]
    
    var ARView: ARSCNView!
    var recordingButton: UIButton!
    var currentFaceNode: SCNNode?

    var videoWriter: AVAssetWriter?
    var videoWriterInput: AVAssetWriterInput?
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    var isReadyForData: Bool? {
        return videoWriterInput?.isReadyForMoreMediaData ?? false
    }
    
    var index: Int = 0
    
    private let videoManager = VideoManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .red
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMustacheSelection(_:)),
            name: Notification.Name("MustacheSelected"),
            object: nil
        )
        loadMustacheSnapshots()
        setupUI()
        setupARSession()
    }
    
    private func setupChooseMustacheView() {
        let contentView = ContentView(data: mustacheImages)
        let hostingController = UIHostingController(rootView: contentView)
        hostingController.view.backgroundColor = .clear
        
        addChild(hostingController)
        view.addSubview(hostingController.view)

        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 46),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -46),
            hostingController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            hostingController.view.heightAnchor.constraint(equalToConstant: 150)
        ])

        hostingController.didMove(toParent: self)
    }
    
    private func setupUI() {
        ARView = ARSCNView()
        ARView.delegate = self
        ARView.translatesAutoresizingMaskIntoConstraints = false

        recordingButton = UIButton(type: .system)
        recordingButton.backgroundColor = .systemGreen
        recordingButton.setImage(UIImage(systemName: "camera.circle"), for: .normal)
        recordingButton.tintColor = .white // 确保系统图标显示正确颜色
        recordingButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        recordingButton.imageView?.contentMode = .scaleAspectFill
        

        recordingButton.layer.cornerRadius = 35 // 圆形，宽高的一半
        recordingButton.layer.masksToBounds = true

        view.addSubview(ARView)
        view.addSubview(recordingButton)
        recordingButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            ARView.topAnchor.constraint(equalTo: view.topAnchor),
            ARView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            ARView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ARView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            recordingButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 120),
            recordingButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordingButton.heightAnchor.constraint(equalToConstant: 70),
            recordingButton.widthAnchor.constraint(equalToConstant: 70)
        ])
        
        setupChooseMustacheView()
    }
    
    var mustacheImages: [UIImage] = []

    let mustacheFileNames = ["Mustache_1", "Mustache_2", "Mustache_3", "Mustache_4", "Mustache_5"]

    func loadMustacheSnapshots() {
        mustacheImages = mustacheFileNames.compactMap { UIImage(named: $0) }
        
        if mustacheImages.isEmpty {
            print("Failed to load mustache images from Assets.")
        } else {
            print("Successfully loaded \(mustacheImages.count) images from Assets.")
        }
    }
    
    @objc private func handleMustacheSelection(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let selectedIndex = userInfo["selectedIndex"] as? Int { // 确保类型安全
            let selectedMustache = "Mustache_\(selectedIndex+1)"
            index = selectedIndex
            updateMustache(style: selectedMustache)
        }
    }

    
    private func addMustache(to node: SCNNode, style: String) {
        let mustacheFileName = "\(style).scn"
        guard let mustacheNode = createMustacheNode(named: mustacheFileName) else {
            print("Failed to load mustache file: \(mustacheFileName)")
            return
        }
        
        let scaleFactors: [String: SCNVector3] = [
            "Mustache_1": SCNVector3(0.0005, 0.00035, 0.00005),
            "Mustache_2": SCNVector3(0.002, 0.002, 0.003594),
            "Mustache_3": SCNVector3(0.0004, 0.0004, 0.00008),
            "Mustache_4": SCNVector3(0.002, 0.002, 0.005),
            "Mustache_5": SCNVector3(0.0005, 0.0005, 0.000686)
        ]
        
        let scale = scaleFactors[style] ?? SCNVector3(1, 1, 1)
        
        mustacheNode.position = SCNVector3(0.0, -0.03, 0.06)
        mustacheNode.scale = scale
        mustacheNode.name = "Mustache"
        node.addChildNode(mustacheNode)
    }
    
    private func createMustacheNode(named nodeName: String) -> SCNNode? {
        guard let mustacheScene = SCNScene(named: nodeName),
              let mustacheNode = mustacheScene.rootNode.childNodes.first else {
            NSLog("Failed to load the node: \(nodeName)")
            return nil
        }
        return mustacheNode
    }

    private func updateMustache(style: String) {
        guard let faceNode = currentFaceNode else { return }
        faceNode.enumerateChildNodes { (node, stop) in
            if node.name == "Mustache" {
                node.removeFromParentNode()
            }
        }
        addMustache(to: faceNode, style: style)
    }
    
    private func setupARSession() {
      guard ARFaceTrackingConfiguration.isSupported else {
        print("AR Face Tracking is not supported on this device.")
        return
      }
      
      let configuration = ARFaceTrackingConfiguration()
        ARView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    //MARK: - Mustache creation methods
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
      guard anchor is ARFaceAnchor else { return }
      
      // Perform on main thread since it updates the UI
      DispatchQueue.main.async {
        self.currentFaceNode = node
        self.addMustache(to: node, style: "Mustache_1")
      }
    }
    
    @objc private func toggleRecording() {
        if isRecording() {
            stopRecording()
            recordingButton.setImage(UIImage(systemName: "camera.circle"), for: .normal)
            recordingButton.backgroundColor = .systemGreen
        } else {
            startRecording()
            recordingButton.setImage(UIImage(systemName: "camera.circle.fill"), for: .normal)
            recordingButton.backgroundColor = .systemRed
        }
    }

    
    
    private func startRecording() {
        print("Recording started successfully.")
        let isMicrophoneEnabled = true
        let recorder = RPScreenRecorder.shared()
        recorder.delegate = self
        recorder.isMicrophoneEnabled = isMicrophoneEnabled
        recorder.startRecording { error in
            if let error = error {
                print("start record failed: \(error.localizedDescription)")
            } else {
                print("start record success")
            }
        }
    }
    
    private func stopRecording() {
        print("Recording stoped successfully.")
        RPScreenRecorder.shared().stopRecording { [weak self] (previewController, error) in
            guard let previewVC = previewController else { return }
            guard let strongSelf = self else { return }
            if error != nil || previewController == nil {
                print("stop failed")
            } else {
                print("stop success")
                previewVC.previewControllerDelegate = self
                strongSelf.present(previewVC, animated: true, completion: {
                    
                })
            }
        }
    }
}


extension MustacheViewController: RPScreenRecorderDelegate {
    
    func screenRecorderDidChangeAvailability(_ screenRecorder: RPScreenRecorder) {
        print("screenRecorder.isAvailable = \(screenRecorder.isAvailable), screenRecorder.isRecording = \(screenRecorder.isRecording)")
    }
}

extension MustacheViewController: RPPreviewViewControllerDelegate {
    
    func previewController(_ previewController: RPPreviewViewController, didFinishWithActivityTypes activityTypes: Set<String>) {
        if activityTypes.contains(UIActivity.ActivityType.saveToCameraRoll.rawValue) {
            print("save")
            saveScreenVideo()
        } else {
            print("cancel save")
        }
    }

    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
        previewController.dismiss(animated: true, completion: nil)
    }

}


extension MustacheViewController {
    private func isRecording() -> Bool {
        if RPScreenRecorder.shared().isRecording {
            return true
        } else {
            return false
        }
    }
    
    private func saveScreenVideo() {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch currentStatus {
        case .authorized:
            uploadVideoFromAsset()
            
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self?.uploadVideoFromAsset()
                    } else {
                        self?.handlePermissionDenied()
                    }
                }
            }
            
        case .denied, .restricted:
            handlePermissionDenied()

        case .limited:
            uploadVideoFromAsset()

        @unknown default:
            print("Unknown authorization status")
        }
    }


    private func handlePermissionDenied() {
        print("No permission to access photo library")
        let alert = UIAlertController(
            title: "Permission Denied",
            message: "Please enable photo library access in Settings to save videos.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        if let topVC = UIApplication.shared.windows.first?.rootViewController {
            topVC.present(alert, animated: true, completion: nil)
        }
    }

    
    private func uploadVideoFromAsset() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let assetsFetchResults = PHAsset.fetchAssets(with: .video, options: options)
        guard let asset = assetsFetchResults.firstObject else { return }

        let assetResource = PHAssetResource.assetResources(for: asset).first
        guard let assetRes = assetResource else { return }

        let manager = PHAssetResourceManager.default()
        var videoData = Data()

        manager.requestData(for: assetRes, options: nil, dataReceivedHandler: { dataChunk in
            videoData.append(dataChunk)
        }) { [weak self] error in
            if error == nil {
                print("Video data loaded, ready to upload")

                guard let selectedIndex = self?.index else {
                    print("Index is nil")
                    return
                }
                self?.uploadVideoData(videoData, selectedIndex: selectedIndex)
            } else {
                print("Failed to load video data: \(error?.localizedDescription ?? "unknown error")")
            }
        }
    }

    private func uploadVideoData(_ videoData: Data, selectedIndex: Int) {
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let createdAt = dateFormatter.string(from: currentDate)
        
        let selectedName = dataSource[selectedIndex]
        print("name  = \(selectedName)")
        let title = "\(selectedName)"
        
        guard let coverImage = UIImage(named: selectedName) else {
            print("Error: Unable to load image from Assets named: \(selectedName)")
            return
        }

        let renderer = UIGraphicsImageRenderer(size: coverImage.size)
        let renderedImage = renderer.image { context in
            UIColor.white.setFill() // 填充背景为白色
            context.fill(CGRect(origin: .zero, size: coverImage.size))
            coverImage.draw(in: CGRect(origin: .zero, size: coverImage.size))
        }

        guard let coverData = renderedImage.jpegData(compressionQuality: 0.8) else {
            print("Error converting rendered image to JPEG data")
            return
        }
        
        videoManager.uploadVideoData(videoData: videoData, coverData: coverData, title: title, tag: selectedName, createdAtData: createdAt, completion: {_ in 
            
        })

        print("Image data size: \(coverData.count) bytes")
    }
    
    private func showAlert(title: String, message: String) {
        let action = UIAlertAction(title: "ok", style: .cancel, handler: nil)
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(action)
        present(alert, animated: false, completion: nil)
    }
    
}
