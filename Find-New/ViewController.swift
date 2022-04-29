//
//  ViewController.swift
//  Find
//
//  Created by A. Zheng (github.com/aheze) on 1/2/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import SwiftUI

class ViewController: UIViewController {
    var loaded = false
    var listToLoad: List?

    var realmModel = RealmModel()

    /// lazy load everything
    lazy var launchViewModel = LaunchViewModel()
    lazy var photosPermissionsViewModel = PhotosPermissionsViewModel()
    lazy var tabViewModel = TabViewModel()
    lazy var photosViewModel = PhotosViewModel()
    lazy var cameraViewModel = CameraViewModel()
    lazy var listsViewModel = ListsViewModel()
    lazy var toolbarViewModel = ToolbarViewModel()

    lazy var settingsController = SettingsController(realmModel: realmModel)
    lazy var photos = PhotosController(
        model: photosViewModel,
        realmModel: realmModel,
        tabViewModel: tabViewModel,
        photosPermissionsViewModel: photosPermissionsViewModel,
        toolbarViewModel: toolbarViewModel
    )
    lazy var camera = CameraController(
        model: cameraViewModel,
        tabViewModel: tabViewModel,
        photosPermissionsViewModel: photosPermissionsViewModel,
        realmModel: realmModel
    )
    lazy var lists = ListsController(
        model: listsViewModel,
        tabViewModel: tabViewModel,
        toolbarViewModel: toolbarViewModel,
        realmModel: realmModel
    )

    var launchViewController: LaunchViewController?

    /// loading this in `viewDidLoad` will cascade and load everything else
    lazy var tabController: TabBarController = {
        let tabController = TabBarController(
            pages: [
                photos.searchNavigationController,
                camera.viewController,
                lists.searchNavigationController
            ],
            model: tabViewModel,
            realmModel: realmModel,
            cameraViewModel: cameraViewModel,
            toolbarViewModel: toolbarViewModel
        )

        self.addChildViewController(tabController.viewController, in: self.view)
        return tabController
    }()

    /// this gets called before `viewDidLoad`, so check `loaded` first
    override var childForStatusBarHidden: UIViewController? {
        if loaded {
            return tabController.viewController
        } else {
            return nil
        }
    }

    override var childForStatusBarStyle: UIViewController? {
        if loaded {
            return tabController.viewController
        } else {
            return nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        realmModel.started()

        if !RealmContainer.migratedPhotoMetadatas.isEmpty || !RealmContainer.migratedLists.isEmpty {
            loadMigratedData(
                migratedPhotoMetadatas: RealmContainer.migratedPhotoMetadatas,
                migratedLists: RealmContainer.migratedLists
            )
        }

        loadApp()

        if realmModel.launchedBefore || Debug.overrideLaunch {
            startApp()
        } else {
            if UIAccessibility.isVoiceOverRunning {
                realmModel.entered()
            } else {
                loadOnboarding()
            }
        }
    }

    // MARK: - Migration

    func loadMigratedData(migratedPhotoMetadatas: [PhotoMetadata], migratedLists: [List]) {
        DispatchQueue.main.async {
            for metadata in migratedPhotoMetadatas {
                self.realmModel.container.updatePhotoMetadata(metadata: metadata, text: nil)
            }

            for list in migratedLists {
                self.realmModel.container.addList(list: list)
            }
        }
    }

    // MARK: - Onboarding

    func loadOnboarding() {
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)

        self.launchViewController = LaunchViewController.make(model: launchViewModel) { [weak self] in
            guard let self = self else { return }
            self.onboardingEntering()
        } done: { [weak self] in
            guard let self = self else { return }
            self.onboardingDone()
        }

        guard let launchViewController = launchViewController else { return }
        addChildViewController(launchViewController, in: view)
        view.bringSubviewToFront(launchViewController.view)
    }

    func onboardingEntering() {
        tabController.viewController.view.transform = .init(scaleX: 1.4, y: 1.4)
        UIView.animate(duration: 0.6, dampingFraction: 1) {
            self.tabController.viewController.view.transform = .identity
        }
    }

    func onboardingDone() {
        guard let launchViewController = launchViewController else { return }
        if !realmModel.launchedBefore && !realmModel.addedListsBefore {
            realmModel.addSampleLists()
        }

        realmModel.entered()
        AppDelegate.AppUtility.lockOrientation(.all)
        removeChildViewController(launchViewController)
        self.launchViewController = nil
        startApp()
    }

    // MARK: - Start App

    func loadApp() {
        loaded = true

        /// start the app up
        _ = tabController

        setup()
        listen()
    }

    func startApp() {
        importListIfNeeded()
    }
}

public extension UIView {
    /// Convert a view's frame to global coordinates, which are needed for `sourceFrame` and `excludedFrames.`
    func windowFrame() -> CGRect {
        return convert(bounds, to: nil)
    }
}

public extension Optional where Wrapped: UIView {
    /// Convert a view's frame to global coordinates, which are needed for `sourceFrame` and `excludedFrames.` This is a convenience overload for optional `UIView`s.
    func windowFrame() -> CGRect {
        if let view = self {
            return view.windowFrame()
        }
        return .zero
    }
}
