//
//  ListsVC+CV.swift
//  Find
//
//  Created by A. Zheng (github.com/aheze) on 1/8/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import UIKit

extension ListsViewController {
    func update(animate: Bool = true) {
        var snapshot = Snapshot()
        let section = DataSourceSectionTemplate()
        snapshot.appendSections([section])
        snapshot.appendItems(model.displayedLists, toSection: section)
        dataSource.apply(snapshot, animatingDifferences: animate)

        if searchViewModel.isEmpty {
            showEmptyContent(model.displayedLists.isEmpty)
            searchViewModel.enabled = !model.displayedLists.isEmpty
        }
        
        updateViewsEnabled()
    }
    
    /// reload the collection view at an index path.
    func update(at indexPath: IndexPath, with displayedList: DisplayedList) {
        if let cell = collectionView.cellForItem(at: indexPath) as? ListsContentCell {
            cell.view.configureData(list: displayedList.list)
            
            DispatchQueue.main.async {
                let (_, columnWidth) = self.listsFlowLayout.getColumns(bounds: self.view.bounds.width, insets: Global.safeAreaInsets)
                _ = self.writeCellFrameAndReturnSize(index: indexPath.item, availableWidth: columnWidth)
                
                cell.view.addChipViews(with: displayedList.list, chipFrames: displayedList.frame.chipFrames)
            }
        }
    }
    
    func makeDataSource() -> DataSource {
        let dataSource = DataSource(collectionView: collectionView) { collectionView, indexPath, cachedDisplayedList -> UICollectionViewCell? in

            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "Cell",
                for: indexPath
            ) as! ListsContentCell
            
            guard let displayedList = self.model.displayedLists.first(where: { $0.list.id == cachedDisplayedList.list.id }) else { return cell }
            let list = displayedList.list
            
            let selected = self.model.selectedLists.contains(where: { $0.id == list.id })
            
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = displayedList.getVoiceoverDescription()
            
            cell.view.configureSelection(selected: selected, modelSelecting: self.model.isSelecting)
            cell.view.configureData(list: list)
            
            cell.tapped = { [weak self] in
                guard let self = self else { return }
                
                if self.model.isSelecting {
                    if self.model.selectedLists.contains(where: { $0.id == list.id }) {
                        self.model.selectedLists = self.model.selectedLists.filter { $0.id != list.id }
                        cell.view.headerSelectionIconView.setState(.empty)
                    } else {
                        self.model.selectedLists.append(list)
                        cell.view.headerSelectionIconView.setState(.selected)
                    }
                } else {
                    if let displayedList = self.model.displayedLists.first(where: { $0.list.id == list.id }) {
                        self.presentDetails(list: displayedList.list)
                    }
                }
            }
            
            return cell
        }
        
        return dataSource
    }
}
