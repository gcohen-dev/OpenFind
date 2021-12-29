//
//  CameraVC+LivePreview.swift
//  Find
//
//  Created by A. Zheng (github.com/aheze) on 12/28/21.
//  Copyright © 2021 A. Zheng. All rights reserved.
//
    
import UIKit

extension CameraViewController {
    func createLivePreview() -> LivePreviewViewController {
        let storyboard = UIStoryboard(name: "CameraContent", bundle: nil)
        let livePreviewViewController = storyboard.instantiateViewController(withIdentifier: "LivePreviewViewController") as! LivePreviewViewController
        
        livePreviewViewController.findFromPhotosButtonPressed = {
            TabControl.moveToOtherTab?(.photos, true)
        }
        
        /// called when an image is first returned
        livePreviewViewController.needSafeViewUpdate = { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                livePreviewViewController.updateViewportSize(safeViewFrame: self.safeView.frame)
                livePreviewViewController.changeZoom(to: self.zoomViewModel.zoom, animated: false)
                livePreviewViewController.changeAspectProgress(to: self.zoomViewModel.aspectProgress, animated: false)
            }
        }
        
        addChild(livePreviewViewController, in: livePreviewContainerView)
        
        livePreviewContainerView.backgroundColor = .clear
        livePreviewViewController.view.backgroundColor = .clear
        return livePreviewViewController
    }
}
