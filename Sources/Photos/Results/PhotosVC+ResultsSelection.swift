//
//  PhotosVC+ResultsSelection.swift
//  Find
//
//  Created by A. Zheng (github.com/aheze) on 3/23/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import UIKit

extension PhotosViewController {
    func photoResultsSelected(at indexPath: IndexPath) {
        guard let resultsState = model.resultsState, let findPhoto = resultsState.displayedFindPhotos[safe: indexPath.item] else { return }

        if !model.selectedPhotos.contains(findPhoto.photo) {
            model.selectedPhotos.append(findPhoto.photo)

            if let cell = resultsCollectionView.cellForItem(at: indexPath) as? PhotosCellResults {
                cell.model.selected = true
                cell.accessibilityTraits = .selected
            }
        }
    }

    func photoResultsDeselected(at indexPath: IndexPath) {
        guard let resultsState = model.resultsState, let findPhoto = resultsState.displayedFindPhotos[safe: indexPath.item] else { return }

        if model.selectedPhotos.contains(findPhoto.photo) {
            model.selectedPhotos = model.selectedPhotos.filter { $0 != findPhoto.photo }

            if let cell = resultsCollectionView.cellForItem(at: indexPath) as? PhotosCellResults {
                cell.model.selected = false
                cell.accessibilityTraits = .none
            }
        }
    }

    func updateResultsCollectionViewSelectionState() {
        guard let resultsState = model.resultsState else { return }
        for index in resultsState.displayedFindPhotos.indices {
            let indexPath = index.indexPath
            if let cell = resultsCollectionView.cellForItem(at: indexPath) as? PhotosCellResults {
                cell.model.showSelectionOverlay = model.isSelecting
                cell.model.selected = false
            }

            if !model.isSelecting {
                resultsCollectionView.deselectItem(at: indexPath, animated: false)
            }
        }
    }
}
