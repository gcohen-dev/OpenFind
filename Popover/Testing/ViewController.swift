//
//  ViewController.swift
//  Popover
//
//  Created by Zheng on 12/3/21.
//  Copyright © 2021 Andrew. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var popoverModel = PopoverModel()
    lazy var popoverController: PopoverController = {
        
        let window = UIApplication.shared
        .connectedScenes
        .filter { $0.activationState == .foregroundActive }
        .first
        
        print("saved: \(SceneConstants.savedScene)")
        
        if let windowScene = SceneConstants.savedScene {
            let popoverController = PopoverController(
                popoverModel: popoverModel,
                windowScene: windowScene
            )
            return popoverController
        }
        
        fatalError("NO scnee")
//        return PopoverController(popoverModel: popoverModel, windowScene: view.window!.windowScene!)
    }()
    
    
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var listLabel: UILabel!
    @IBAction func wordPressed(_ sender: Any) {
        popoverModel.fieldSettings = .init(
            origin: wordLabel.frame.origin,
            defaultColor: 0x00aeef,
            selectedColor: 0x00aeef,
            alpha: 0.5
        )
    }
    
    @IBAction func listPressed(_ sender: Any) {
    }
    
    
    @IBAction func tipPressed(_ sender: Any) {
    }
    
    @IBAction func holdDown(_ sender: Any) {
    }
    
    @IBAction func holdUp(_ sender: Any) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("widnow \(view.window?.windowScene)")
        
        _ = popoverController
    }


}

