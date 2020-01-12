//
//  ViewExtensions.swift
//  Find
//
//  Created by Andrew on 10/29/19.
//  Copyright © 2019 Andrew. All rights reserved.
//

import UIKit
import ARKit

///Blur Screen & Refresh Screen
extension ViewController {
    
//    func changeHUDSize(to shape: CGSize) {
//        
//        for pip in self.pipPositionViews {
//            let constraints = pip.constraints
//            for constraint in constraints {
//                if constraint.identifier == "matchesPositionViewWidth" {
//                    constraint.constant = shape.width
//                }
//                if constraint.identifier == "matchesPositionViewHeight" {
//                    constraint.constant = shape.height
//                }
//            }
//        }
//        for constraintt in view.constraints {
//            var subtractYesNo = false
//            if shape.height == 55 {
//                subtractYesNo = false
//            } else if shape.height == 120 {
//                subtractYesNo = true
//            }
//            ///120-55 = 65
//            ///65/2=32.5
//            if constraintt.identifier == "topVert" {
//                if subtractYesNo == true {
//                    constraintt.constant = constraintt.constant - 32.5
//                } else if subtractYesNo == false {
//                    constraintt.constant = constraintt.constant + 32.5
//                }
//            }
//        }
//        
//        if shape.height == shape.width {
//            self.upButtonToNumberConstraint.isActive = false
//            self.downButtonToNumberConstraint.isActive = false
//        } else {
//            self.upButtonToNumberConstraint.isActive = true
//            self.downButtonToNumberConstraint.isActive = true
//        }
//        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
//            ///The below line of code caused the weird orientation bug, which also occurred in the previous version of Find (FindBetaOld on GitHub).
//            //self.view.layoutIfNeeded()
//            
//            self.matchesBig.layoutIfNeeded()
//            if shape.height == shape.width {
//                self.upButton.alpha = 0
//                self.downButton.alpha = 0
//            } else {
//                self.upButton.alpha = 1
//                self.downButton.alpha = 1
//            }
//            
//        }) { _ in
//               if shape.height == shape.width {
//                    self.upButton.isHidden = true
//                    self.downButton.isHidden = true
//                } else {
//                    self.upButton.isHidden = false
//                    self.downButton.isHidden = false
//                }
//                self.matchesHeightConstraint.constant = shape.height
//                self.matchesWidthConstraint.constant = shape.width
//                UIView.animate(withDuration: 0.3, animations: {
//                    self.view.layoutIfNeeded()
//                })
//            }
//    
//    }
    
    func blurScreen(mode: String) {
        let effect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: effect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.alpha = 0
        view.addSubview(blurView)
        view.bringSubviewToFront(blurView)
        //view.bringSubviewToFront(photoButton)
       // view.bringSubviewToFront(modeButton)
        view.bringSubviewToFront(newShutterButton)
       // view.bringSubviewToFront(refreshButton)
        view.bringSubviewToFront(menuButton)
        view.bringSubviewToFront(ramReel.view)
        guard let tag1 = self.view.viewWithTag(1) else {return}
        guard let tag2 = self.view.viewWithTag(2) else {return}
        switch mode {
        
        case "classic":
            //to classic
            
            sceneView.session.pause()
            UIView.animate(withDuration: 0.2, animations: {
                blurView.alpha = 1
                tag1.alpha = 0
                tag2.alpha = 0
            }, completion: { _ in
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = .horizontal
                self.sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
             //   self.modeButton.imageView.image = #imageLiteral(resourceName: "bclassic 2")
                //self.fastFindingToggle = .inactive
                self.busyFastFinding = true
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: {
                UIView.animate(withDuration: 0.5, animations: {blurView.alpha = 0}, completion: {_ in
                    blurView.removeFromSuperview()})
            })
        case "focus":
            //focusmode
            sceneView.session.pause()
            UIView.animate(withDuration: 0.2, animations: {
                blurView.alpha = 1
                tag1.alpha = 1
                tag2.alpha = 1
            }, completion: { _ in
                self.fadeClassicHighlights()
                self.runImageTrackingSession(with: [], runOptions: [.removeExistingAnchors, .resetTracking])
              //  self.modeButton.imageView.image = #imageLiteral(resourceName: "bfocus 2")
                //self.fastFindingToggle = .inactive
                self.busyFastFinding = true
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: {
                UIView.animate(withDuration: 0.5, animations: {blurView.alpha = 0}, completion: {_ in
                    blurView.removeFromSuperview()})
            })
        case "fast":
            print("fast")
            sceneView.session.pause()
            //fastTextDetectionRequest.customWords = ["sfhskfh 98ohkjshgosro9g u oh xvhdfogiuerouoeugorugo lhxlvhflfgu"]
            UIView.animate(withDuration: 0.2, animations: {
                blurView.alpha = 1
                tag1.alpha = 0
                tag2.alpha = 0
            }, completion: { _ in
                self.fadeClassicHighlights()
                self.sceneView.session.run(self.fastSceneConfiguration, options: [.removeExistingAnchors, .resetTracking])
            //    self.modeButton.imageView.image = #imageLiteral(resourceName: "bfast 2")
                //self.fastFindingToggle = false
                self.busyFastFinding = false
                
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {
                UIView.animate(withDuration: 0.3, animations: {blurView.alpha = 0}, completion: {_ in
                    blurView.removeFromSuperview()})
                ///make it seem like it's FAST (the blur fades much faster)
            })
            
        default:
            print("error, default, blur")
        }
    }
    
    func refreshScreen(location: CGPoint) {
        var option = RippleEffect.option()
        //var xOrig = deviceSize.width / 2
        option.fillColor = #colorLiteral(red: 0, green: 0.6823529412, blue: 0.937254902, alpha: 1)
        option.radius = CGFloat(50)
        option.borderWidth = CGFloat(0)
        option.scale = CGFloat(14)
        option.duration = 0.38
        //option.isRunSuperView = true
        print("sgh")
        RippleEffect.run(sceneView, locationInView: location, option: option)
        
        
            switch self.scanModeToggle {
            case .classic:
                self.stopProcessingImage = true
                self.classicTimer.suspend()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: {self.stopProcessingImage = false})
                let action = SCNAction.fadeOut(duration: 1)
                for h in self.classicHighlightArray {
                    h.runAction(action, completionHandler: {() in
                        h.removeFromParentNode()
                        print("remove")
                    })
                }
                for h in self.secondClassicHighlightArray {
                    h.runAction(action, completionHandler: {
                        () in h.removeFromParentNode()
                        print("remove123")
                    })
                }
                self.classicTimer.resume()
            case .focused:
                //self.stopTagFindingInNode = true
                self.focusTimer.suspend()
                self.runImageTrackingSession(with: [], runOptions: [.resetTracking, .removeExistingAnchors])
                self.focusTimer.resume()
                self.coachingOverlay.activatesAutomatically = false
                //self.stopTagFindingInNode = false
            case .fast:
                self.resetFastHighlights()
                self.updateMatchesNumber(to: 0)
            }
    }
    func fadeClassicHighlights() {
        let action = SCNAction.fadeOut(duration: 1)
        for h in self.classicHighlightArray {
            h.runAction(action, completionHandler: {() in
                h.removeFromParentNode()
                print("remove")
            })
        }
        for h in self.secondClassicHighlightArray {
            h.runAction(action, completionHandler: {
                () in h.removeFromParentNode()
                print("remove123")
            })
        }
    }
    
}


