//
//  VC+Setup.swift
//  Find
//
//  Created by A. Zheng (github.com/aheze) on 2/12/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//
    

import UIKit
import Popovers

extension ViewController {
    func setup() {
        Popovers.minimumDragDistance = 3
        setupTabs()
    }
}
