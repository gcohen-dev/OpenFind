//
//  PhotosViewController.swift
//  Photos
//
//  Created by Zheng on 11/18/21.
//

import SwiftUI

public class PhotosViewController: UIViewController, PageViewController {
    
    public var tabType: TabState = .photos
    var photosSelectionViewModel: ToolbarViewModel.PhotosSelection!
    
    public lazy var selectionToolbar: PhotosSelectionToolbarView = {
        return PhotosSelectionToolbarView(viewModel: photosSelectionViewModel)
    }()
    
    public var getActiveToolbarViewModel: (() -> ToolbarViewModel)?
    
    /// active, animate
    public var activateSelectionToolbar: ((Bool, Bool) -> Void)?
    
    
    @IBAction func selectPressed(_ sender: Any) {
        if let activeToolbarViewModel = getActiveToolbarViewModel?() {
            if activeToolbarViewModel.toolbar == .photosSelection {
                self.activateSelectionToolbar?(false, false)
            } else {
                self.activateSelectionToolbar?(true, false)
            }
        }
    }
    @IBAction func addPressed(_ sender: Any) {
        print("add pressed")
        photosSelectionViewModel.selectedCount += 1
    }
    @IBAction func minusPressed(_ sender: Any) {
        print("mnus pressed")
        photosSelectionViewModel.selectedCount -= 1
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        print("Photos loaded")
        
        self.photosSelectionViewModel = .init()
    }
}

extension PhotosViewController {
    public func willBecomeActive() {
        
    }
    
    public func didBecomeActive() {
        
    }
    
    public func willBecomeInactive() {
//        print("Becoming inactve.")
        self.activateSelectionToolbar?(false, true)
    }
    
    public func didBecomeInactive() {
        
    }
}

public struct PhotosSelectionToolbarView: View {
    @ObservedObject var viewModel: ToolbarViewModel.PhotosSelection
    
    public var body: some View {
        HStack {
            ToolbarIconButton(iconName: viewModel.starOn ? "star.fill" : "star") {
                viewModel.starOn.toggle()
            }
            .disabled(viewModel.selectedCount == 0)
            
            Text("\(viewModel.selectedCount) Photos Selected")
                .font(.system(.headline))
                .frame(maxWidth: .infinity)
            
            ToolbarIconButton(iconName: "trash") {
            }
            .disabled(viewModel.selectedCount == 0)
        }
    }
}
struct ToolbarIconButton: View {
    var iconName: String
    var action: (() -> Void)
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(Font(Constants.iconFont))
        }
    }
}
