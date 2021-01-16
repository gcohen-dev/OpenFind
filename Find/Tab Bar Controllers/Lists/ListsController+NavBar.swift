//
//  ListsController+NavBar.swift
//  Find
//
//  Created by Zheng on 12/29/20.
//  Copyright © 2020 Andrew. All rights reserved.
//

import UIKit

extension ListsController {
    func setupBarButtons() {
        addButton = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(addPressed(sender:)))
        selectButton = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(selectPressed(sender:)))
        
        addButton.tintColor = UIColor(hexString: randomizedColor)
        navigationItem.rightBarButtonItems = [addButton, selectButton]
        
        updateSelectionLabel?(0)
    }
    @objc func addPressed(sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "ListBuilderViewController") as? ListBuilderViewController {
            viewController.listBuilderType = .maker
            viewController.newListDelegate = self
            viewController.iconColorName = randomizedColor
            viewController.isModalInPresentation = true
            self.present(viewController, animated: true, completion: nil)
        }
    }
    @objc func selectPressed(sender: UIBarButtonItem) {
        selectPressed()
    }
    
}
