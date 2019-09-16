import UIKit
import SpriteKit
import ARKit
import Vision

class ViewController: UIViewController, UIGestureRecognizerDelegate, ARSKViewDelegate, ARSessionDelegate {
    private let fireNode = SKReferenceNode(fileNamed: "Fire")!
    @IBOutlet weak var sceneView: ARSKView!
    private var screenWidth: CGFloat = 0
    private var screenHeight: CGFloat = 0
    
    private lazy var statusViewController: StatusViewController = {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let overlayScene = SKScene()
        overlayScene.scaleMode = .aspectFill
        sceneView.delegate = self
        sceneView.presentScene(overlayScene)
        sceneView.session.delegate = self
        
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartSession()
        }
        screenWidth = view.bounds.width
        screenHeight = view.bounds.height
        
        fireNode.setScale(0.0002)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }
        
        self.currentBuffer = frame.capturedImage
        detectObjectsOnCurrentImage()
    }
    
    private lazy var detectionRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: CandleDetector().model)
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processDetection(for: request, error: error)
            })
            
            request.imageCropAndScaleOption = .scaleFill
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    private var currentBuffer: CVPixelBuffer?
    
    private let visionQueue = DispatchQueue(label: "com.makeml.candle_fire")
    
    private func detectObjectsOnCurrentImage() {
        let orientation = CGImagePropertyOrientation(UIDevice.current.orientation)
        
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: currentBuffer!, orientation: orientation)
        visionQueue.async {
            do {
                defer { self.currentBuffer = nil }
                try requestHandler.perform([self.detectionRequest])
            } catch {
                print("Error: Vision request failed with error \"\(error)\"")
            }
        }
    }
    
    private var identifierString = ""
    private var confidence: VNConfidence = 0.0
    func processDetection(for request: VNRequest, error: Error?) {
        guard let results = request.results else {
            print("Unable to detect objects on image.\n\(error!.localizedDescription)")
            return
        }
        let detectionResults = results as! [VNRecognizedObjectObservation]
        
        if let bestResult = detectionResults.first(where: { result in result.confidence > 0.7 }) {
            identifierString = String(bestResult.labels[0].identifier)
            
            let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -screenHeight)
            let scale = CGAffineTransform.identity.scaledBy(x: screenWidth, y: screenHeight)
            let normalRect = bestResult.boundingBox.applying(scale).applying(transform)

            let point = CGPoint(x: normalRect.origin.x + normalRect.size.width/2, y: normalRect.origin.y + normalRect.size.height/2)
            let hitTestResults = sceneView.hitTest(point, types: [.featurePoint, .estimatedHorizontalPlane])
            
            confidence = bestResult.confidence
            if let result = hitTestResults.first {
                let anchor = ARAnchor(transform: result.worldTransform)
                sceneView.session.add(anchor: anchor)
            }
        } else {
            identifierString = ""
            confidence = 0
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.displayDetectionResults()
        }
    }
    
    private func displayDetectionResults() {
        guard !self.identifierString.isEmpty else {
            return
        }
        let message = String(format: "Detected \(self.identifierString) with %.2f", self.confidence * 100) + "% confidence"
        statusViewController.showMessage(message)
    }
    
    func view(_ view: ARSKView, didAdd node: SKNode, for anchor: ARAnchor) {
        fireNode.removeFromParent()
        node.addChild(fireNode)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        statusViewController.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
        
        switch camera.trackingState {
        case .notAvailable, .limited:
            statusViewController.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            statusViewController.cancelScheduledMessage(for: .trackingStateEscalation)
            setOverlaysHidden(false)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        setOverlaysHidden(true)
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }

    private func setOverlaysHidden(_ shouldHide: Bool) {
        sceneView.scene!.children.forEach { node in
            if shouldHide {
                node.alpha = 0
            } else {
                node.run(.fadeIn(withDuration: 0.5))
            }
        }
    }

    private func restartSession() {
        statusViewController.cancelAllScheduledMessages()
        statusViewController.showMessage("RESTARTING SESSION")
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func displayErrorMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.restartSession()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
}
