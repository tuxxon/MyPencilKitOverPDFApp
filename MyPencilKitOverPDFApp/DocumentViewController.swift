//
//  DocumentViewController.swift
//  MyPencilKitOverPDFApp
//
//  Created by rossit on 29/07/2023.
//

import UIKit
import PDFKit
import UniformTypeIdentifiers

extension PDFView {
    func panWithTwoFingers() {
        for view in self.subviews {
            if let subView = view as? UIScrollView {
                subView.isScrollEnabled = true
                subView.panGestureRecognizer.minimumNumberOfTouches = 2
            }
        }
    }
}

class DocumentViewController: UIViewController, UIDocumentPickerDelegate {
    
    @IBOutlet weak var saveButton: UIButton?
    @IBOutlet weak var drawBoxButton: UIButton?
    @IBOutlet weak var pdfView: PDFView?
    
    var pdfDocumentURL: URL?
    
    var document: Document?
    
    var overlayCoordinator: MyOverlayCoordinator = MyOverlayCoordinator()
    
    var openOrSave: Bool = false
    var isCustomDraw: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.pdfView?.displayDirection = .vertical
        self.pdfView?.pageOverlayViewProvider = self.overlayCoordinator
        self.pdfView?.isInMarkupMode = true
        self.pdfView?.panWithTwoFingers()
        self.customDragGesture()
    }
    
    @IBAction func openSaveTouched() {
        if self.openOrSave {
            print("   -> Save touched !")
            self.save()
            self.saveButton?.setTitle("Open", for: .normal)
        } else {
            print("   -> Open touched !")
            self.openDocumentPicker()
            self.saveButton?.setTitle("Save", for: .normal)
        }
        self.openOrSave.toggle()
    }
    
    @IBAction func toggleCustomBoxMode(_ sender: UIButton) {
        isCustomDraw.toggle() // Toggle custom box drawing mode with button
        sender.setTitle(isCustomDraw ? "CustomBox On" : "CustomBox Off", for: .normal)
        print("[DocumentViewController] CustomBox mode changed: \(isCustomDraw)")
        
        guard let pdfPage = pdfView?.currentPage as? MyPDFPage,
              let canvasView = pdfPage.canvasView else {
            print("[DocumentViewController] canvasView not found.")
            return
        }

        // Set canvasView's drawingGestureRecognizer
        canvasView.drawingGestureRecognizer.isEnabled = !isCustomDraw
        print("[DocumentViewController] drawingGestureRecognizer set - isEnabled: \(!isCustomDraw)")


    }
    
    private func customDragGesture() {
        // Add finger gesture.
        let fingerDragGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDrag(_:)))
        fingerDragGesture.allowedTouchTypes = [UITouch.TouchType.direct.rawValue as NSNumber] // Allow only finger
        pdfView?.addGestureRecognizer(fingerDragGesture)
        print("[DocumentViewController] Finger gesture added")
        
        // Add Apple Pencil gesture
        let pencilDragGesture = UIPanGestureRecognizer(target: self, action: #selector(handleDrag(_:)))
        pencilDragGesture.allowedTouchTypes = [UITouch.TouchType.stylus.rawValue as NSNumber] // Allow only Apple Pencil
        pdfView?.addGestureRecognizer(pencilDragGesture)
        print("[DocumentViewController] Apple Pencil gesture added")
    }
    
    private func openDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.pdf])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    private func openDocument(at url: URL) {
        self.pdfDocumentURL = url
        
        self.document = Document(fileURL: url)
        
        document?.open(completionHandler: { (success) in
            if success {
                print(" 1.3 - Document opened")
                self.document?.pdfDocument?.delegate = self // PDFDocumentDelegate
                self.pdfView?.document = self.document?.pdfDocument
                self.displaysDocument()
            } else {
                // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
            }
        })
    }
    
    @objc func handleDrag(_ gesture: UIPanGestureRecognizer) {
        print("[DocumentViewController] handleDrag called")
        
        // Check flag for custom box drawing mode
        guard isCustomDraw else { // Modify this as needed
            print("[DocumentViewController] Custom box drawing mode is not active")
            return
        }
        
        let location = gesture.location(in: gesture.view)
        print("[DocumentViewController] Gesture location: \(location)")
        
        switch gesture.state {
        case .began:
            print("[DocumentViewController] Gesture began")
            // Start drawing the custom box here
        case .changed:
            print("[DocumentViewController] Gesture changed")
            // Update the custom box drawing here
        case .ended:
            print("[DocumentViewController] Gesture ended")
            // Complete the custom box drawing here
        default:
            print("[DocumentViewController] Gesture state: \(gesture.state.rawValue)")
            break
        }
    }

    private func save() {
        
        print("   2 - Saves document")

        guard let url = self.pdfDocumentURL,
        let document = self.document else {
            return
        }
        
        self.pdfView?.document = nil
        
        print("Will then try to save at URL : \(url)")
        
        document.close(completionHandler: { (success) in
            if success {
                document.save(to: url,
                              for: .forOverwriting,
                              completionHandler: { (success) in
                    print(" 2.4 - Saved at \(url)")
                })
            } else {
                print("Sorry, error !")
            }
        })
    }
    
    private func displaysDocument() {
        guard let document = self.pdfView?.document,
              let page: MyPDFPage = document.page(at: 0) as? MyPDFPage else {
            return
        }
        // Setup canvas for MyPDFPage
        self.setupCanvasView(at: page)
        
        guard let pageCanvasView = page.canvasView else {
            return
        }
        MyPDFKitToolPickerModel.shared.toolPicker.setVisible(true, forFirstResponder: pageCanvasView)
        pageCanvasView.becomeFirstResponder()
    }
    
    private func setupCanvasView(at page: MyPDFPage) {
        if page.canvasView == nil,
           let storedCanvas = self.overlayCoordinator.pageToViewMapping[page] {
            page.canvasView = storedCanvas
        } else {
            // create canvasView
            page.canvasView = self.overlayCoordinator.overlayView(for: page)
        }
    }
    
    // MARK: - UIDocumentPickerDelegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        openDocument(at: url)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled")
    }
}

extension DocumentViewController: PDFDocumentDelegate {
    public func classForPage() -> AnyClass {
        print(" 1.4 - Request custom page type?")
        return MyPDFPage.self
    }
    
    public func `class`(forAnnotationType annotationType: String) -> AnyClass {
        switch annotationType {
        case MyPDFAnnotation.drawingDataKey:
            return MyPDFAnnotation.self
        default:
            return PDFAnnotation.self
        }
    }
}
