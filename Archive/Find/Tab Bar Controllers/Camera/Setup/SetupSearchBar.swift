//
//  SetupSearchBar.swift
//  Find
//
//  Created by Andrew on 11/11/19.
//  Copyright © 2019 Andrew. All rights reserved.
//

import ARKit
import SnapKit
import UIKit
import VideoToolbox

protocol InjectLists: class {
    func addList(list: EditableFindList)
    func resetWithLists(lists: [EditableFindList])
}

extension CameraViewController: ToolbarButtonPressed, SelectedList, StartedEditing {
    func buttonPressed(button: ToolbarButtonType) {
        switch button {
        case .newMatch:
            if let selectedRange = newSearchTextField.selectedTextRange {
                let cursorPosition = newSearchTextField.offset(from: newSearchTextField.beginningOfDocument, to: selectedRange.start)
                if let textFieldText = newSearchTextField.text {
                    var newText = textFieldText
                    newText.insert(string: "\u{2022}", ind: cursorPosition)
                    
                    newSearchTextField.text = newText
                    
                    if let cursorLocation = newSearchTextField.position(from: newSearchTextField.beginningOfDocument, offset: cursorPosition + 1) {
                        newSearchTextField.selectedTextRange = newSearchTextField.textRange(from: cursorLocation, to: cursorLocation)
                    }
                }
            }

        case .done:
            temporaryPreventGestures?(false)
            view.endEditing(true)
            if insertingListsCount == 0 {
                updateListsLayout(toType: "doneAndShrink")
            } else {
                isSchedulingList = true
            }
        }
    }

    func addList(list: EditableFindList) {
        selectedLists.insert(list, at: 0)
        if selectedLists.count <= 1 {
            updateListsLayout(toType: "addListsNow")
        }
        
        let indexP = IndexPath(item: 0, section: 0)
        searchCollectionView.performBatchUpdates({
            self.searchCollectionView.insertItems(at: [indexP])
            self.insertingListsCount += 1
        }, completion: { _ in
            self.insertingListsCount -= 1
            if self.isSchedulingList == true {
                if self.insertingListsCount == 0 {
                    self.isSchedulingList = false
                    self.updateListsLayout(toType: "doneAndShrink")
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                UIAccessibility.post(notification: .announcement, argument: "Moved to selected lists")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    if let cell = self.searchCollectionView.cellForItem(at: indexP) {
                        UIAccessibility.post(notification: .layoutChanged, argument: cell.contentView)
                    }
                }
            }
        })
        sortSearchTerms()
        if CameraState.isPaused {
            if !cachedComponents.isEmpty, cachePressed {
                addCacheResults()
            }
            findWhenPaused()
        }
    }

    func startedEditing(start: Bool) {
        if start == true {
            if selectedLists.count == 0 {
                updateListsLayout(toType: "onlyTextBox")
            } else {
                updateListsLayout(toType: "addListsNow")
            }
        } else {
            updateListsLayout(toType: "doneAndShrink")
        }
    }
}

extension CameraViewController: UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedLists.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = searchCollectionView.dequeueReusableCell(withReuseIdentifier: "searchCell", for: indexPath) as! SearchCell
        let listNumber = selectedLists[indexPath.item]
        if let list = listCategories?[listNumber.orderIdentifier] {
            cell.backgroundColor = UIColor(hexString: list.iconColorName)
            cell.layer.cornerRadius = 6
               
            let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 10, weight: .semibold)
            let newImage = UIImage(systemName: list.iconImageName, withConfiguration: symbolConfiguration)?.withTintColor(UIColor.white, renderingMode: .alwaysOriginal)

            cell.imageView.image = newImage
            
            if searchShrunk == true {
                cell.imageRightC.constant = 0
                UIView.animate(withDuration: 0.3, animations: {
                    cell.nameLabel.text = ""
                    cell.nameLabel.alpha = 0
                    cell.layoutIfNeeded()
                })
            } else {
                cell.imageRightC.constant = 8
                UIView.animate(withDuration: 0.3, animations: {
                    cell.nameLabel.text = list.name
                    cell.nameLabel.alpha = 1
                    cell.layoutIfNeeded()
                })
            }

            cell.contentView.isAccessibilityElement = true
            cell.contentView.accessibilityLabel = "Selected list"
            
            if searchShrunk {
                cell.contentView.accessibilityHint = "Double-tap to expand the search bar and view all selected lists."
            } else {
                cell.contentView.accessibilityHint = "Double-tap to remove the list. Moves it back to the toolbar."
            }
            
            let colorDescription = list.iconColorName.getDescription()
            
            let listName = AccessibilityText(text: list.name, isRaised: false)
            let iconTitle = AccessibilityText(text: "\nIcon", isRaised: true)
            let iconString = AccessibilityText(text: list.iconImageName, isRaised: false)
            let colorTitle = AccessibilityText(text: "\nColor", isRaised: true)
            let colorString = AccessibilityText(text: "\(colorDescription.0)", isRaised: false)
            let pitchTitle = AccessibilityText(text: "\nPitch", isRaised: true)
            let pitchString = AccessibilityText(text: "\(colorDescription.1)", isRaised: false, customPitch: colorDescription.1)
            
            let accessibilityLabel = UIAccessibility.makeAttributedText(
                [
                    listName,
                    iconTitle, iconString,
                    colorTitle, colorString,
                    pitchTitle, pitchString
                ]
            )
            
            cell.contentView.accessibilityAttributedValue = accessibilityLabel
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if searchShrunk == false {
            let list = selectedLists[indexPath.item]
            
            selectedLists.remove(at: indexPath.item)
            searchCollectionView.deleteItems(at: [indexPath])
            
            if selectedLists.count == 0 {
                updateListsLayout(toType: "removeListsNow")
            }
            
            injectListDelegate?.addList(list: list)
            sortSearchTerms()
            if CameraState.isPaused {
                if !cachedComponents.isEmpty, cachePressed {
                    addCacheResults()
                }
                findWhenPaused()
            }
        } else {
            newSearchTextField.becomeFirstResponder()
            if selectedLists.count == 0 {
                updateListsLayout(toType: "onlyTextBox")
            } else {
                updateListsLayout(toType: "addListsNow")
            }
        }
    }

    func loadListsRealm() {
        listCategories = realm.objects(FindList.self)
        selectedLists.removeAll()
        editableListCategories.removeAll()

        listCategories = listCategories!.sorted(byKeyPath: "dateCreated", ascending: false)
        if let lC = listCategories {
            for (index, singleL) in lC.enumerated() {
                let editList = EditableFindList()

                editList.name = singleL.name
                editList.descriptionOfList = singleL.descriptionOfList
                editList.iconImageName = singleL.iconImageName
                editList.iconColorName = singleL.iconColorName
                editList.dateCreated = singleL.dateCreated
                editList.orderIdentifier = index
                var contents = [String]()
                for singleCont in singleL.contents {
                    contents.append(singleCont)
                }

                editList.contents = contents

                editableListCategories.append(editList)
            }
        }
        searchCollectionView.reloadData()
    }

    func setupSearchBar() {
        textLabel.alpha = 0
        listsLabel.alpha = 0
        tapToRemoveLabel.alpha = 0
        arrowDownImage.alpha = 0
        
        searchContentView.layer.cornerRadius = 12
        searchContentView.clipsToBounds = true
        
        newSearchTextField.layer.cornerRadius = 8
        
        let typeHereToFind = NSLocalizedString("typeHereToFind", comment: "SetupSearchBar def=Type here to find...")
        
        newSearchTextField.attributedPlaceholder = NSAttributedString(string: typeHereToFind,
                                                                      attributes:
                                                                      [NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.8784313725, green: 0.878935039, blue: 0.878935039, alpha: 0.75)])
        
        alternateWarningView.alpha = 0
        alternateWarningView.layer.cornerRadius = 6
        alternateWarningView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        alternateWarningLabel.alpha = 0
        
        let onlyPortraitSupported = NSLocalizedString("onlyPortraitSupported", comment: "SetupSearchBar def=Only Portrait view is currently supported.")
        let rotateToPortrait = NSLocalizedString("rotateToPortrait", comment: "SetupSearchBar def=Please rotate your iPad to Portrait view, then relaunch the app.")
        
        alternateWarningLabel.text = "\(onlyPortraitSupported)\n\(rotateToPortrait)"
        
        warningView.alpha = 0
        warningView.layer.cornerRadius = 6
        warningView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        warningLabel.alpha = 0
        let findPausedDuplicatesNotAllowed = NSLocalizedString("findPausedDuplicatesNotAllowed", comment: "SetupSearchBar def=Find is paused | Duplicates are not allowed")
        warningLabel.text = findPausedDuplicatesNotAllowed
        searchBarLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        
        let toolbar = ListToolBar()
        toolbar.location = .inCamera
        toolbar.pressedButton = self
        toolbar.selectedList = self
        toolbar.startedEditing = self
        
        injectListDelegate = toolbar
        loadListsRealm()
        
        toolbar.frame.size = CGSize(width: deviceSize.width, height: 80)
        toolbar.editableListCategories = editableListCategories
        
        newSearchTextField.inputAccessoryView = toolbar
        
        toolbar.pressedButton = self
        toolbar.selectedList = self
        toolbar.startedEditing = self
        
        toolbar.forceDarkMode()
        
        self.toolbar = toolbar
    }

    func updateListsLayout(toType: String) {
        switch toType {
        case "onlyTextBox":
            searchShrunk = false
            searchCollectionRightC.constant = 0
            searchBarLayout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            searchCollectionView.reloadData()
            searchTextLeftC.constant = 8
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                self.newSearchTextField.backgroundColor = UIColor(named: "OpaqueBlur")
                self.view.layoutIfNeeded()
            }, completion: nil)
            topGroupView.accessibilityElements = [searchBackgroundView, newSearchTextField]
        case "addListsNow":

            if searchShrunk == true {
                searchShrunk = false
                searchCollectionRightC.constant = 0
                searchBarLayout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
                searchCollectionView.reloadData()
            }
            searchTextLeftC.constant = 8
            searchTextTopC.constant = 180
            searchCollectionTopC.constant = 60
            searchContentViewHeight.constant = 243
            
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                self.searchCollectionView.alpha = 1
                self.arrowDownImage.alpha = 1
                self.textLabel.alpha = 1
                self.listsLabel.alpha = 1
                self.tapToRemoveLabel.alpha = 1
                self.view.layoutIfNeeded()
            }, completion: nil)
            
            topGroupView.accessibilityElements = [searchBackgroundView, listsLabel, listsDownIndicatorView, searchCollectionView, textLabel, newSearchTextField]
        case "removeListsNow":

            searchTextTopC.constant = 8
            searchCollectionTopC.constant = 8
            searchContentViewHeight.constant = 71
            
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                self.searchCollectionView.alpha = 0
                self.textLabel.alpha = 0
                self.listsLabel.alpha = 0
                self.arrowDownImage.alpha = 0
                
                self.tapToRemoveLabel.alpha = 0
                self.view.layoutIfNeeded()
            }, completion: nil)
            
            topGroupView.accessibilityElements = [searchBackgroundView, newSearchTextField]
        case "prepareForDisplayNew":
            searchTextLeftC.constant = 8
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        case "doneAndShrink":
            searchCollectionView.performBatchUpdates({
                self.searchShrunk = true
            }, completion: { _ in
                self.searchCollectionView.reloadData()
            })
            
            switch selectedLists.count {
            case 0:
                break
            case 1:
                searchTextLeftC.constant = 71
            case 2:
                searchTextLeftC.constant = 71 + 55 + 8
            case 3:
                searchTextLeftC.constant = 197
            default:
                searchTextLeftC.constant = 197
                let availableWidth = searchContentView.frame.width - 189
                searchBarLayout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 0)
                searchCollectionRightC.constant = availableWidth
            }
            
            searchContentViewHeight.constant = 71
            searchTextTopC.constant = 8
            searchCollectionTopC.constant = 8
            
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
                self.newSearchTextField.backgroundColor = UIColor(named: "TransparentBlur")
                self.textLabel.alpha = 0
                self.listsLabel.alpha = 0
                self.tapToRemoveLabel.alpha = 0
                self.view.layoutIfNeeded()
            })
            
            if selectedLists.count >= 1 {
                topGroupView.accessibilityElements = [searchBackgroundView, searchCollectionView, newSearchTextField]
            } else {
                topGroupView.accessibilityElements = [searchBackgroundView, newSearchTextField]
            }
        default:
            break
        }
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        temporaryPreventGestures?(true)
        if selectedLists.count == 0 {
            updateListsLayout(toType: "onlyTextBox")
        } else {
            updateListsLayout(toType: "addListsNow")
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        temporaryPreventGestures?(false)
        view.endEditing(true)
        if insertingListsCount == 0 {
            updateListsLayout(toType: "doneAndShrink")
        } else {
            isSchedulingList = true
        }
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let updatedString = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) {
            let splits = updatedString.components(separatedBy: "\u{2022}")
            let uniqueSplits = splits.uniques
            if uniqueSplits.count != splits.count {
                resetHighlights()
                allowSearch = false
                showDuplicateAlert(show: true)
            } else {
                showDuplicateAlert(show: false)
                allowSearch = true
                finalTextToFind = updatedString
                sortSearchTerms()
            }
        }
        
        /// if paused, find
        if CameraState.isPaused {
            if !cachedComponents.isEmpty, cachePressed {
                addCacheResults()
            }
            findWhenPaused()
        }
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        finalTextToFind = ""
        allowSearch = true
        resetHighlights()
        showDuplicateAlert(show: false)
        sortSearchTerms()
        return true
    }

    func showDuplicateAlert(show: Bool) {
        if show == true {
            warningHeightC.constant = 32
            UIView.animate(withDuration: 0.5, animations: {
                self.warningView.alpha = 1
                self.warningLabel.alpha = 1
                self.view.layoutIfNeeded()
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                UIAccessibility.post(notification: .layoutChanged, argument: self.warningView)
            }
        } else {
            warningHeightC.constant = 0
            UIView.animate(withDuration: 0.5, animations: {
                self.warningView.alpha = 0
                self.warningLabel.alpha = 0
                self.view.layoutIfNeeded()
            })
        }
    }

    func sortSearchTerms(removeExistingHighlights: Bool = true) {
        let lowerCaseFinalText = finalTextToFind.lowercased()
        var arrayOfSearch = lowerCaseFinalText.components(separatedBy: "\u{2022}")
        var cameAcrossShare = [String]()
        var duplicatedStrings = [String]()
        
        if removeExistingHighlights {
            resetHighlights()
        }
        
        matchToColors.removeAll()
        
        var cameAcrossSearchFieldText = [String]()
        for list in selectedLists {
            for match in list.contents {
                if !cameAcrossShare.contains(match.lowercased()) {
                    cameAcrossShare.append(match.lowercased())
                } else {
                    duplicatedStrings.append(match)
                }
                
                if arrayOfSearch.contains(match.lowercased()) {
                    cameAcrossSearchFieldText.append(match)
                }
            }
        }
        duplicatedStrings = duplicatedStrings.uniques
        cameAcrossSearchFieldText = cameAcrossSearchFieldText.uniques
        for list in selectedLists {
            for match in list.contents {
                let matchColor = UIColor(hexString: list.iconColorName).cgColor
                let highlightColor = HighlightColor(cgColor: matchColor, hexString: list.iconColorName)
                
                if !duplicatedStrings.contains(match.lowercased()), !cameAcrossSearchFieldText.contains(match.lowercased()) {
                    matchToColors[match.lowercased()] = [highlightColor]
                    
                } else {
                    if matchToColors[match.lowercased()] == nil {
                        matchToColors[match.lowercased()] = [highlightColor]
                    } else {
                        if !(matchToColors[match.lowercased()]?.contains(highlightColor))! {
                            matchToColors[match.lowercased(), default: [HighlightColor]()].append(highlightColor)
                        }
                    }
                }
            }
        }
        var newSearch = [String]()
        for match in arrayOfSearch {
            if match != "", !cameAcrossSearchFieldText.contains(match), !duplicatedStrings.contains(match) {
                newSearch.append(match)
            }
        }
        arrayOfSearch = newSearch
        
        for match in arrayOfSearch {
            let colorString = UserDefaults.standard.string(forKey: "highlightColor") ?? "00AEEF"
            let cgColor = UIColor(hexString: colorString).cgColor
            let highlightColor = HighlightColor(cgColor: cgColor, hexString: colorString)
            
            matchToColors[match] = [highlightColor]
        }
        
        for match in cameAcrossSearchFieldText {
            let colorString = UserDefaults.standard.string(forKey: "highlightColor") ?? "00AEEF"
            let cgColor = UIColor(hexString: colorString).cgColor
            let highlightColor = HighlightColor(cgColor: cgColor, hexString: colorString)
            
            matchToColors[match, default: [HighlightColor]()].append(highlightColor)
        }
    }

    func convertToUIImage(buffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: buffer)
        let temporaryContext = CIContext(options: nil)
        if let temporaryImage = temporaryContext.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(buffer), height: CVPixelBufferGetHeight(buffer)))
        {
            let capturedImage = UIImage(cgImage: temporaryImage, scale: 1.0, orientation: .right)
            return capturedImage
        }
        return nil
    }
}

extension String {
    mutating func insert(string: String, ind: Int) {
        insert(contentsOf: string, at: index(startIndex, offsetBy: ind))
    }
}
