//
//  LaunchViewController.swift
//  Find
//
//  Created by Zheng on 3/31/20.
//  Copyright © 2020 Andrew. All rights reserved.
//

import AVFoundation
import SnapKit
import UIKit

enum LaunchAction {
    case onboarding
    case fullScreenStart
    case needPermissions
    case denied
    case restricted
}

class LaunchViewController: UIViewController {
    // MARK: Status bar

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if traitCollection.userInterfaceStyle == .light {
            return FindConstantVars.shouldHaveLightStatusBar ? .lightContent : .darkContent
        } else {
            return .lightContent
        }
    }

    override var prefersStatusBarHidden: Bool {
        if isForcingStatusBarHidden {
            additionalSafeAreaInsets.top = 20
            return true
        } else {
            return !FindConstantVars.shouldHaveStatusBar
        }
    }
    
    /// Hold the main view controller
    @IBOutlet var containerView: UIView!
    @IBOutlet var blueCoverView: UIView!
    
    @IBOutlet var baseView: UIView!
    @IBOutlet var topLeftImageView: UIImageView!
    @IBOutlet var topRightImageView: UIImageView!
    @IBOutlet var bottomLeftImageView: UIImageView!
    @IBOutlet var bottomRightImageView: UIImageView!
    
    @IBOutlet var totalWidthC: NSLayoutConstraint!
    @IBOutlet var totalHeightC: NSLayoutConstraint!
    
    @IBOutlet var allowAccessView: UIView!
    @IBOutlet var allowAccessButton: UIButton!
    
    @IBOutlet var allowAccessWidthC: NSLayoutConstraint!
    @IBOutlet var allowAccessViewHeightC: NSLayoutConstraint!
    
    var innerViewMaxWidth = CGFloat(0)
    var innerViewMaxHeight = CGFloat(0)
    var cornersViewMaxWidth = CGFloat(0)
    var cornersViewMaxHeight = CGFloat(0)
    
    let topHeight = CGFloat(70)
    
    @IBOutlet var permissionsTitleView: UIView!
    @IBOutlet var accessDescLabel: UILabel!
    
    var onboardingOnLastPage = false
    
    @IBAction func allowAccessPressed(_ sender: Any) {
        if shouldGoToSettings {
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        } else {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
                if granted {
                    DispatchQueue.main.async {
                        UIView.animate(withDuration: 0.5, animations: {
                            self.allowAccessView.alpha = 0
                            self.allowAccessView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
                        }) { _ in
                            self.drawAnimation(type: .fullScreenStart)
                        }
                    }
                } else {
                    self.shouldGoToSettings = true
                    self.firstTimeDeny = false
                    DispatchQueue.main.async {
                        self.drawAnimation(type: .denied)
                    }
                }
            })
        }
    }

    var shouldGoToSettings = false
    var firstTimeDeny = false
    
    @IBOutlet var settingsPictureView: UIImageView!
    
    @IBOutlet var skipButton: UIButton!
    @IBAction func skipPressed(_ sender: Any) {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "launchedBefore")
        
        defaults.set("00AEEF", forKey: "highlightColor")
        defaults.set(true, forKey: "showTextDetectIndicator")
        defaults.set(2, forKey: "hapticFeedbackLevel")
        defaults.set(1, forKey: "shutterStyle")
        defaults.set(true, forKey: "swipeToNavigateEnabled")
        
        UIView.animate(withDuration: 0.5, animations: {
            self.onboarding.alpha = 0
            self.onboarding.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
            self.getStartedButton.alpha = 0
            self.getStartedButton.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
            self.skipButton.alpha = 0
        })
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:

            drawAnimation(type: .fullScreenStart)
        case .notDetermined:
            shouldGoToSettings = false
            drawAnimation(type: .needPermissions)
        case .denied:
            firstTimeDeny = true
            shouldGoToSettings = true
            drawAnimation(type: .denied)
        case .restricted:
            drawAnimation(type: .restricted)
        @unknown default:
            fatalError()
        }
    }

    @IBOutlet var onboarding: PaperOnboarding!
    
    @IBOutlet var getStartedButton: UIButton!
    @IBAction func getStartedPressed(_ sender: Any) {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "launchedBefore")
        defaults.set("00AEEF", forKey: "highlightColor")
        defaults.set(true, forKey: "showTextDetectIndicator")
        defaults.set(true, forKey: "hapticFeedback")
        
        UIView.animate(withDuration: 0.5, animations: {
            self.onboarding.alpha = 0
            self.onboarding.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
            self.getStartedButton.alpha = 0
            self.getStartedButton.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
            self.skipButton.alpha = 0
        })
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:

            drawAnimation(type: .fullScreenStart)
        case .notDetermined:
            shouldGoToSettings = false
            drawAnimation(type: .needPermissions)
        case .denied:
            firstTimeDeny = true
            shouldGoToSettings = true
            drawAnimation(type: .denied)
        case .restricted:
            drawAnimation(type: .restricted)
        @unknown default:
            fatalError()
        }
    }
    
    @IBOutlet var onboardingTopC: NSLayoutConstraint!
    @IBOutlet var onboardingWidthC: NSLayoutConstraint!
    @IBOutlet var onboardingHeightC: NSLayoutConstraint!
    
    let defaults = UserDefaults.standard
    
    var appearedBefore = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !appearedBefore {
            appearedBefore = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                FindConstantVars.shouldHaveLightStatusBar = true
                UIView.animate(withDuration: 0.3) {
                    if !isForcingStatusBarHidden {
                        self.setNeedsStatusBarAppearanceUpdate()
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FindConstantVars.launchViewController = self
        
        skipButton.alpha = 0
        
        getStartedButton.alpha = 0
        getStartedButton.layer.cornerRadius = 6
        getStartedButton.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
        
        allowAccessView.alpha = 0
        allowAccessView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        
        settingsPictureView.alpha = 0
        
        allowAccessButton.layer.cornerRadius = 6
        allowAccessView.layer.cornerRadius = 10
        
        topRightImageView.transform = CGAffineTransform(rotationAngle: CGFloat(-270).degreesToRadians)
        bottomLeftImageView.transform = CGAffineTransform(rotationAngle: CGFloat(-90).degreesToRadians)
        bottomRightImageView.transform = CGAffineTransform(rotationAngle: CGFloat(-180).degreesToRadians)
        
        let defaults = UserDefaults.standard
        let launchedBefore = defaults.bool(forKey: "launchedBefore")
        if launchedBefore == false {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.drawAnimation(type: .onboarding)
            }
        } else {
            onboarding.removeFromSuperview()
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.drawAnimation(type: .fullScreenStart)
                }
            case .notDetermined:
                shouldGoToSettings = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.drawAnimation(type: .needPermissions)
                }
            case .denied:
                firstTimeDeny = true
                shouldGoToSettings = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.drawAnimation(type: .denied)
                }
            case .restricted:
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.drawAnimation(type: .restricted)
                }
            @unknown default:
                break
            }
        }
        
        getStartedButton.accessibilityLabel = "Continue"
        getStartedButton.accessibilityHint = "Finish tutorial"
    }
    
    let goToSettings = NSLocalizedString("universal-goToSettings", comment: "")
    
    func drawAnimation(type: LaunchAction) {
        innerViewMaxWidth = view.bounds.width - CGFloat(70)
        innerViewMaxHeight = view.bounds.height - CGFloat(topHeight * 2)
        cornersViewMaxWidth = view.bounds.width - CGFloat(20)
        cornersViewMaxHeight = view.bounds.height - CGFloat(topHeight * 2 - 50)
        
        let restrictedInnerViewWidth = min(400 - 50, innerViewMaxWidth)
        let restrictedInnerViewHeight = min(400 - 50, innerViewMaxHeight)
        let restrictedCornersViewWidth = min(400, cornersViewMaxWidth)
        let restrictedCornersViewHeight = min(400, cornersViewMaxHeight)
        
        switch type {
        case .restricted:
            allowAccessView.alpha = 0
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                self.baseView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }) { _ in
                self.totalWidthC.constant = restrictedInnerViewWidth
                self.totalHeightC.constant = restrictedInnerViewWidth
                self.allowAccessViewHeightC.constant = restrictedCornersViewWidth
                self.allowAccessWidthC.constant = restrictedCornersViewWidth
                
                UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
                    self.view.layoutIfNeeded()
                    self.baseView.transform = CGAffineTransform.identity
                    self.allowAccessView.transform = CGAffineTransform.identity
                    self.allowAccessView.alpha = 1
                    
                    self.skipButton.alpha = 0
                    
                })
            }
            
            let noPermissionToUseCamera = NSLocalizedString("noPermissionToUseCamera", comment: "LaunchViewController def=You don't have permission to use the camera.")
            
            accessDescLabel.text = noPermissionToUseCamera
            shouldGoToSettings = true
            allowAccessButton.setTitle(goToSettings, for: .normal)
        case .denied:
            
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                self.baseView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }) { _ in
                
                self.allowAccessWidthC.constant = restrictedInnerViewWidth
                self.allowAccessViewHeightC.constant = self.innerViewMaxHeight
                self.totalWidthC.constant = restrictedCornersViewWidth
                self.totalHeightC.constant = self.cornersViewMaxHeight
                
                UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
                    self.view.layoutIfNeeded()
                    self.baseView.transform = CGAffineTransform.identity
                    self.allowAccessView.transform = CGAffineTransform.identity
                    self.allowAccessView.alpha = 1
                    self.settingsPictureView.alpha = 1
                })
            }
            DispatchQueue.main.async {
                self.allowAccessButton.setTitle(self.goToSettings, for: .normal)
            }
            
        case .needPermissions:
            
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                self.baseView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }) { _ in
                self.allowAccessWidthC.constant = restrictedInnerViewWidth
                self.allowAccessViewHeightC.constant = restrictedInnerViewHeight
                self.totalWidthC.constant = restrictedCornersViewWidth
                self.totalHeightC.constant = restrictedCornersViewHeight
                UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
                    self.view.layoutIfNeeded()
                    self.baseView.transform = CGAffineTransform.identity
                    self.allowAccessView.transform = CGAffineTransform.identity
                    self.allowAccessView.alpha = 1
                    
                    UIAccessibility.post(notification: .screenChanged, argument: self.permissionsTitleView)
                })
            }
            
        case .onboarding:
            
            onboarding.dataSource = self
            onboarding.delegate = self
            onboarding.alpha = 0
            onboarding.transform = CGAffineTransform(scaleX: 0.2, y: 0.2)
            onboarding.layer.cornerRadius = 10
            onboarding.clipsToBounds = true
            
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                self.baseView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }) { _ in
                self.onboardingTopC.constant = self.topHeight
                self.onboardingWidthC.constant = self.innerViewMaxWidth
                self.onboardingHeightC.constant = self.innerViewMaxHeight
                
                self.view.layoutIfNeeded()
                self.view.bringSubviewToFront(self.skipButton)
                
                self.totalWidthC.constant = self.cornersViewMaxWidth
                self.totalHeightC.constant = self.cornersViewMaxHeight
                
                UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseOut, animations: {
                    self.view.layoutIfNeeded()
                    self.baseView.transform = CGAffineTransform.identity
                    self.onboarding.alpha = 1
                    self.onboarding.transform = CGAffineTransform.identity
                    
                    self.skipButton.alpha = 1
                })
            }
        case .fullScreenStart:
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = storyboard.instantiateViewController(withIdentifier: "ViewController")
            
            addChild(viewController, in: containerView)
            containerView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                self.baseView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            }) { _ in
                let finalWidth = self.view.bounds.width
                let finalHeight = self.view.bounds.height
                self.totalWidthC.constant = finalWidth
                self.totalHeightC.constant = finalHeight
                
                UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.5, options: .curveLinear, animations: {
                    self.baseView.layoutIfNeeded()
                    self.baseView.transform = CGAffineTransform.identity
                    self.fadeEverything()
                    self.containerView.transform = CGAffineTransform.identity
                }) { _ in
                    self.removeEverything()
                }
            }
        }
    }
    
    func fadeEverything() {
        blueCoverView?.alpha = 0
        baseView?.alpha = 0
        getStartedButton?.alpha = 0
        allowAccessView?.alpha = 0
        skipButton?.alpha = 0
        onboarding?.alpha = 0
    }

    func removeEverything() {
        blueCoverView?.removeFromSuperview()
        baseView?.removeFromSuperview()
        getStartedButton?.removeFromSuperview()
        allowAccessView?.removeFromSuperview()
        skipButton?.removeFromSuperview()
        onboarding?.removeFromSuperview()
    }
}

extension LaunchViewController: PaperOnboardingDelegate, PaperOnboardingDataSource {
    func onboardingWillTransitonToIndex(_ index: Int) {
        if index == 0 {
            UIView.animate(withDuration: 0.15, animations: {
                self.skipButton.alpha = 1
            })
        } else {
            UIView.animate(withDuration: 0.15, animations: {
                self.skipButton.alpha = 0
            })
        }
        
        if index == 3 {
            onboardingOnLastPage = true
            getStartedButton.alpha = 0
            onboardingHeightC.constant = innerViewMaxHeight - 60
            UIView.animate(withDuration: 0.15, animations: {
                self.getStartedButton.transform = CGAffineTransform.identity
                self.view.layoutIfNeeded()
                self.getStartedButton.alpha = 1
            }) { _ in
                UIAccessibility.post(notification: .layoutChanged, argument: self.getStartedButton)
            }
        } else {
            if onboardingOnLastPage == true {
                onboardingOnLastPage = false
                getStartedButton.alpha = 1
                onboardingHeightC.constant = innerViewMaxHeight
                UIView.animate(withDuration: 0.15, animations: {
                    self.view.layoutIfNeeded()
                    self.getStartedButton.transform = CGAffineTransform(scaleX: 0.4, y: 0.4)
                    self.getStartedButton.alpha = 0
                })
            }
        }
    }
}

extension LaunchViewController {
    func onboardingItem(at index: Int) -> OnboardingItemInfo {
        let firstDescription = UIAccessibility.isVoiceOverRunning ? "Find text in real life, fast. Swipe up or down on the Page chooser to navigate this tutorial." : LaunchLocalization.swipeToGetStarted
        
        return [
            OnboardingItemInfo(informationImage: UIImage(named: "Intro1")!,
                               title: LaunchLocalization.welcomeToFind,
                               description: firstDescription,
                               pageIcon: UIImage(),
                               color: UIColor(named: "OnboardBlue")!,
                               titleColor: UIColor.white,
                               descriptionColor: UIColor.white,
                               titleFont: UIFont.systemFont(ofSize: 30, weight: .bold),
                               descriptionFont: UIFont.systemFont(ofSize: 17)),
            
            OnboardingItemInfo(informationImage: UIImage(named: "Intro2")!,
                               title: LaunchLocalization.camera,
                               description: LaunchLocalization.cameraDescription,
                               pageIcon: UIImage(named: "Page1")!,
                               color: UIColor(named: "OnboardBlue")!,
                               titleColor: UIColor.white,
                               descriptionColor: UIColor.white,
                               titleFont: UIFont.systemFont(ofSize: 22, weight: .bold),
                               descriptionFont: UIFont.systemFont(ofSize: 17)),
            
            OnboardingItemInfo(informationImage: UIImage(named: "Intro3")!,
                               title: LaunchLocalization.photos,
                               description: LaunchLocalization.photosDescription,
                               pageIcon: UIImage(named: "Page2")!,
                               color: UIColor(named: "OnboardBlue")!,
                               titleColor: UIColor.white,
                               descriptionColor: UIColor.white,
                               titleFont: UIFont.systemFont(ofSize: 22, weight: .bold),
                               descriptionFont: UIFont.systemFont(ofSize: 17)),
            
            OnboardingItemInfo(informationImage: UIImage(named: "Intro4")!,
                               title: LaunchLocalization.lists,
                               description: LaunchLocalization.listsDescription,
                               pageIcon: UIImage(named: "Page3")!,
                               color: UIColor(named: "OnboardBlue")!,
                               titleColor: UIColor.white,
                               descriptionColor: UIColor.white,
                               titleFont: UIFont.systemFont(ofSize: 22, weight: .bold),
                               descriptionFont: UIFont.systemFont(ofSize: 17))
        ][index]
    }
    
    func onboardingItemsCount() -> Int {
        return 4
    }
}
