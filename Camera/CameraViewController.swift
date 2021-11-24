//
//  CameraViewController.swift
//  Camera
//
//  Created by Zheng on 11/18/21.
//

import SwiftUI
import Combine

public class CameraViewController: UIViewController, PageViewController {
    
    public var tabType: TabState = .camera
    var cameraViewModel: ToolbarViewModel.Camera!
    var zoomViewModel: ZoomViewModel!
    
    
    private var zoomCancellable: AnyCancellable?
    private var aspectProgressCancellable: AnyCancellable?
    
    @IBOutlet weak var searchContainerView: UIView!
    @IBOutlet weak var searchContainerHeightC: NSLayoutConstraint!
    
    @IBOutlet weak var zoomContainerView: UIView!
    @IBOutlet weak var zoomContainerHeightC: NSLayoutConstraint!
    
    @IBOutlet weak var livePreviewContainerView: UIView!
    lazy var livePreviewViewController: LivePreviewViewController = {
        
        
        let storyboard = UIStoryboard(name: "CameraContent", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "LivePreviewViewController") as! LivePreviewViewController
        
        viewController.findFromPhotosButtonPressed = { [weak self] in
            TabControl.moveToOtherTab?(.photos, true)
        }
        viewController.needSafeViewUpdate = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                viewController.updateViewportSize(safeViewFrame: self.safeView.frame)
                viewController.changeZoom(to: self.zoomViewModel.zoom, animated: false)
                viewController.changeAspectProgress(to: self.zoomViewModel.aspectProgress)
            }
        }
        
        self.addChild(viewController, in: livePreviewContainerView)
        
        livePreviewContainerView.backgroundColor = .clear
        viewController.view.backgroundColor = .clear
        return viewController
    }()
    
    @IBOutlet weak var safeView: UIView!
    
    
    public lazy var toolbar: CameraToolbarView = {
        self.cameraViewModel = .init()
        return CameraToolbarView(viewModel: cameraViewModel)
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        print("Camera loaded")
        print("View bounds: \(view.bounds)")
        setup()
        
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        livePreviewViewController.updateViewportSize(safeViewFrame: safeView.frame)
        safeView.frame.setAsConstraints(
            left: livePreviewViewController.safeViewLeftC,
            top: livePreviewViewController.safeViewTopC,
            width: livePreviewViewController.safeViewWidthC,
            height: livePreviewViewController.safeViewHeightC
        )
    }
    
    func setup() {
        view.backgroundColor = Constants.darkBlueBackground
        safeView.backgroundColor = .clear
        
        self.zoomViewModel = .init(containerView: zoomContainerView)
        let zoomView = ZoomView(zoomViewModel: self.zoomViewModel)
        let hostingController = UIHostingController(rootView: zoomView)
        hostingController.view.backgroundColor = .clear
        addChild(hostingController, in: zoomContainerView)
        zoomContainerView.backgroundColor = .clear
        
        zoomCancellable = zoomViewModel.$zoom.sink { [weak self] zoom in
            self?.livePreviewViewController.changeZoom(to: zoom, animated: true)
        }
        aspectProgressCancellable = zoomViewModel.$aspectProgress.sink { [weak self] aspectProgress in
            self?.livePreviewViewController.changeAspectProgress(to: aspectProgress)
        }
        
        
        
        _ = livePreviewViewController
        
        if let camera = livePreviewViewController.cameraDevice {
            zoomViewModel.configureZoomFactors(
                minZoom: camera.minAvailableVideoZoomFactor,
                maxZoom: camera.maxAvailableVideoZoomFactor,
                switchoverFactors: camera.virtualDeviceSwitchOverVideoZoomFactors
            )
        }
        
        searchContainerHeightC.constant = 100
    }
}

extension CameraViewController {
    public func willBecomeActive() {
        
    }
    
    public func didBecomeActive() {
        
    }
    
    public func willBecomeInactive() {
        
    }
    
    public func didBecomeInactive() {
            
    }
}

public struct CameraToolbarView: View {
    @ObservedObject var viewModel: ToolbarViewModel.Camera
    
    public var body: some View {
        HStack(alignment: .top, spacing: 0) {
            HStack {
                ResultsIconView(count: $viewModel.resultsCount)
                Spacer()
                FlashIconView(isOn: $viewModel.flashOn)
            }
            .frame(maxWidth: .infinity)

            Color.clear

            HStack {
                FocusIconView(isOn: $viewModel.focusOn)
                Spacer()
                SettingsIconView()
            }
            .frame(maxWidth: .infinity)
        }
    }
}


