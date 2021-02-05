//
//  GeneralViewController.swift
//  Find
//
//  Created by Andrew on 2/7/20.
//  Copyright © 2020 Andrew. All rights reserved.
//

import UIKit
import RealmSwift
import SwiftEntryKit

protocol GetGeneralInfo: class {
    func returnFinishedGeneral(nameOfList: String, desc: String, contentsOfList: [String])
}
protocol DeleteList: class {
    func deleteList()
}
class GeneralViewController: UIViewController {
    
    func receiveGeneral(nameOfList: String, desc: String, contentsOfList: [String]) {
        print("general recieved")
        name = nameOfList
        descriptionOfList = desc
        contents = contentsOfList
    }
    
    
    weak var generalDelegate: GetGeneralInfo?

    @IBOutlet var titlesInputView: UIView!
    @IBOutlet var descInputView: UIView!
    @IBOutlet var inputButtonsView: UIView!

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomActionView: UIView!
    @IBOutlet weak var matchesHeader: UIView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var tableBottomView: UIView!
    
    
    @IBOutlet weak var newMatchButton: UIButton!
    @IBOutlet weak var newMatchPlus: UIButton!
    
    @IBAction func newMatchPressed(_ sender: Any) {
        addNewRow(end: true)
    }
    
    @IBAction func newMatchPlusPressed(_ sender: Any) {
        addNewRow(end: true)
    }
    
    var currentIndexPath = 0
    var addingNewMatch = false
    var emptyStringErrors = [Int]()
    
    var singleSpaceWarning = [Int]()
    var startSpaceWarning = [Int]()
    var endSpaceWarning = [Int]()
    
    var shouldHighlightRows = false
    
    
    var generalSpaces = [String: [Int]]()
    
    var stringToIndexesError = [String: [Int]]() ///A dictionary of the DUPLICATE rows- not the first occurance. These rows should be deleted.
    
    
    var deleteThisList: (() -> Void)?
    
    weak var delegate: UIAdaptivePresentationControllerDelegate?
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var descriptionView: UITextView!
    var placeholderLabel : UILabel!
    
    // MARK: Editing properties
    var name = ""
    var descriptionOfList = ""
    var contents = [String]()
    

    func highlightRowsOnError(type: String) { ///Highlight the rows when done is pressed and there is an error
        
        switch type {
        case "EmptyMatch":
            var reloadPaths = [IndexPath]()
            for ind in emptyStringErrors {
                let indPath = IndexPath(row: ind, section: 0)
                
                if let cell = tableView.cellForRow(at: indPath) as? GeneralTableCell {
                    UIView.animate(withDuration: 0.1, animations: {
                        cell.overlayView.backgroundColor = #colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)
                        cell.animateDupSlide()
                    })
                } else {
                    reloadPaths.append(indPath)
                }
            }
            
            shouldHighlightRows = true
            tableView.reloadRows(at: reloadPaths, with: .none)
            
        case "Duplicate":
            var indInts = [Int]()
            
            for intArray in stringToIndexesError.values {
                for intError in intArray {
                    if !indInts.contains(intError) {
                        indInts.append(intError)
                    }
                }
            }
            var reloadPaths = [IndexPath]()
            for ind in indInts {
                let indPath = IndexPath(row: ind, section: 0)
                
                if let cell = tableView.cellForRow(at: indPath) as? GeneralTableCell {
                    UIView.animate(withDuration: 0.1, animations: {
                        cell.overlayView.backgroundColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
                        cell.animateDupSlide()
                    })
                } else {
                    reloadPaths.append(indPath)
                }
            }
            
            shouldHighlightRows = true
            tableView.reloadRows(at: reloadPaths, with: .none)
        default:
            print("ERROR!!>>")
        }
    }
//    func showWarningIcon() {
//        checkForErrors(contentsArray: contents)
//        generalSpaces.removeAll()
//        for singleSpace in singleSpaceWarning {
//            //print("singlespace")
//            generalSpaces["Single", default: [Int]()].append(singleSpace)
//        }
//        for startSpace in startSpaceWarning {
//            //print("Startspace")
//            generalSpaces["Start", default: [Int]()].append(startSpace)
//        }
//        for endSpace in endSpaceWarning {
//            //print("Endspace")
//            generalSpaces["End", default: [Int]()].append(endSpace)
//        }
//
//    }
    
    @IBOutlet weak var descDoneButton: UIButton!
    @IBAction func descButtonDonePressed(_ sender: Any) {
        view.endEditing(true)
    }
    
    @IBOutlet weak var titlesDoneButton: UIButton!
    @IBAction func titlesButtonDonePressed(_ sender: Any) {
        view.endEditing(true)
    }
    @IBOutlet weak var contentsDoneButton: UIButton!
    @IBAction func contentsDonePressed(_ sender: Any) {
        view.endEditing(true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        bottomDeleteButton.layer.cornerRadius = 6
        bottomHelpButton.layer.cornerRadius = 6
        
        setupViews()
        let tableViewHeightAfterAddRow = CGFloat(50 * contents.count)
        
        if tableViewHeightAfterAddRow >= 300 {
            tableViewHeightConstraint.constant = tableViewHeightAfterAddRow
            UIView.animate(withDuration: 0.75, animations: {
                self.view.layoutIfNeeded()
            })
        }
        
    }
    
    @IBOutlet weak var bottomDeleteButton: UIButton!
    @IBOutlet weak var bottomHelpButton: UIButton!
    
    @IBAction func bottomDeletePressed(_ sender: Any) {
        
        let cancel = NSLocalizedString("cancel", comment: "Multipurpose def=Cancel")
        let delete = NSLocalizedString("delete", comment: "Multipurpose def=Delete")
        let confirmDeleteList = NSLocalizedString("confirmDeleteList", comment: "Are you sure you want to delete this list?")
        let cantUndoDeleteList = NSLocalizedString("cantUndoDeleteList", comment: "You can't undo this action.")
        
        
        let alert = UIAlertController(title: confirmDeleteList, message: cantUndoDeleteList, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: delete, style: UIAlertAction.Style.destructive, handler: { _ in
            
            self.deleteThisList?()
            
            SwiftEntryKit.dismiss()
          
        }))
        alert.addAction(UIAlertAction(title: cancel, style: UIAlertAction.Style.cancel, handler: nil))
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = bottomDeleteButton
            popoverController.sourceRect = bottomDeleteButton.bounds
        }
        self.present(alert, animated: true, completion: nil)
        
    }
    /// stopper **HERE**
    @IBAction func bottomHelpPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let helpViewController = storyboard.instantiateViewController(withIdentifier: "DefaultHelpController") as! DefaultHelpController
        
        let help = NSLocalizedString("help", comment: "Multipurpose def=Help")
        helpViewController.title = help
        
//        let navigationController = UINavigationController(rootViewController: helpViewController)
//        navigationController.view.backgroundColor = UIColor.clear
//        navigationController.navigationBar.tintColor = UIColor.white
//        navigationController.navigationBar.prefersLargeTitles = true
//        
//        let navBarAppearance = UINavigationBarAppearance()
//        navBarAppearance.configureWithOpaqueBackground()
//        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
//        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
//        navBarAppearance.backgroundColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
//        navigationController.navigationBar.standardAppearance = navBarAppearance
//        navigationController.navigationBar.scrollEdgeAppearance = navBarAppearance
//        
//        
//        navigationController.view.layer.cornerRadius = 10
//        UINavigationBar.appearance().barTintColor = .black
//        helpViewController.edgesForExtendedLayout = []
//        
//        var attributes = EKAttributes.centerFloat
//        attributes.displayDuration = .infinity
//        attributes.entryInteraction = .absorbTouches
//        attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .easeOut)
//        attributes.shadow = .active(with: .init(color: .black, opacity: 0.5, radius: 10, offset: .zero))
//        attributes.screenBackground = .color(color: EKColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.3802521008)))
//        attributes.entryBackground = .color(color: .white)
//        attributes.screenInteraction = .absorbTouches
//        attributes.positionConstraints.size.height = .constant(value: screenBounds.size.height - CGFloat(100))
//        
//        
//        attributes.positionConstraints.maxSize = .init(width: .constant(value: 600), height: .constant(value: 800))
//        
//        SwiftEntryKit.display(entry: navigationController, using: attributes)
//        
//        

        let navigationController = UINavigationController(rootViewController: helpViewController)
        navigationController.navigationBar.tintColor = UIColor.white
        navigationController.navigationBar.prefersLargeTitles = true

        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.backgroundColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
        
        navigationController.navigationBar.standardAppearance = navBarAppearance
        navigationController.navigationBar.scrollEdgeAppearance = navBarAppearance
        
        self.present(navigationController, animated: true, completion: nil)
    }
    
    
    func addNewRow(end: Bool = false) {
        addingNewMatch = true
        
        if end == false { ///User pressed return to insert
          //  print("Return INSERT")
            contents.insert("", at: currentIndexPath + 1)
            
            let tableViewHeightAfterAddRow = CGFloat(50 * contents.count)
            
            if tableViewHeightAfterAddRow >= 300 {
                tableViewHeightConstraint.constant = tableViewHeightAfterAddRow
                UIView.animate(withDuration: 0.75, animations: {
                    self.view.layoutIfNeeded()
                })
            }
            
            
//            checkForErrors(contentsArray: contents)
            currentIndexPath = currentIndexPath + 1
            tableView.insertRows(at: [IndexPath(row: currentIndexPath, section: 0)], with: .automatic)
            
            if currentIndexPath < contents.count - 1 {
                let endRange = currentIndexPath + 1...contents.count - 1
                
                var reloadPaths = [IndexPath]()
                for singleRow in endRange {
                    let deleteIndP = IndexPath(row: singleRow, section: 0)
                    
                    if let cell = tableView.cellForRow(at: deleteIndP) as? GeneralTableCell {
                        cell.indexPath += 1
                    } else {
                        reloadPaths.append(deleteIndP)
                    }
                }
                
                tableView.reloadRows(at: reloadPaths, with: .automatic)
            }
            
            
        } else {
            contents.append("")
            let tableViewHeightAfterAddRow = CGFloat(50 * contents.count)
            
            print("HEIGHT CONT: \(tableViewHeightAfterAddRow)")
            if tableViewHeightAfterAddRow >= 300 {
                tableViewHeightConstraint.constant = tableViewHeightAfterAddRow
                UIView.animate(withDuration: 0.75, animations: {
                    self.view.layoutIfNeeded()
                })
            }
            currentIndexPath = contents.count - 1
            tableView.insertRows(at: [IndexPath(row: currentIndexPath, section: 0)], with: .automatic)
        }
        
    }
    func deleteRow(row: Int) {
        contents.remove(at: row)
        let tableViewHeightAfterAddRow = CGFloat(50 * contents.count)
        
        print("HEIGHT CONT: \(tableViewHeightAfterAddRow)")
        if tableViewHeightAfterAddRow >= 300 {
            tableViewHeightConstraint.constant = tableViewHeightAfterAddRow
            UIView.animate(withDuration: 0.75, animations: {
                self.view.layoutIfNeeded()
            })
        }
        
//        checkForErrors(contentsArray: contents)
        let indP = IndexPath(row: row, section: 0)
        tableView.deleteRows(at: [indP], with: .automatic)
        
        print("del CURR IND: \(row)....count: \(contents.count)")
        if row == contents.count { ///Cont count is now 1 less because remove
            print("last row")
        } else {
            print("Not last row")
            let endRange = row...contents.count - 1
            
            var reloadPaths = [IndexPath]()
            for singleRow in endRange {
                let deleteIndP = IndexPath(row: singleRow, section: 0)
                
                if let cell = tableView.cellForRow(at: deleteIndP) as? GeneralTableCell {
                    cell.indexPath -= 1
                } else {
                    reloadPaths.append(deleteIndP)
                }
            }
            
            tableView.reloadRows(at: reloadPaths, with: .automatic)
            
        }
        
        
        if contents.count == 0 {
            addingNewMatch = true
            contents = [""]
            currentIndexPath = 0
            tableView.insertRows(at: [IndexPath(row: currentIndexPath, section: 0)], with: .automatic)
        }
    }
    func setupViews() {
        if contents.count == 0 {
            contents.append("")
        }
        
        ///Receive info
        
        titleField.text = name
        descriptionView.text = descriptionOfList
        
        
        topView.layer.cornerRadius = 8
        
        titleField.autocapitalizationType = .words
        titleField.inputAccessoryView = titlesInputView
        
        descriptionView.inputAccessoryView = descInputView
        descriptionView.layer.cornerRadius = 5.25
        descriptionView.layer.borderWidth = 1
        descriptionView.layer.borderColor = UIColor(named: "TextRim")?.resolvedColor(with: self.traitCollection).cgColor
            
        titleField.layer.cornerRadius = 5.25
        titleField.layer.borderColor = UIColor(named: "TextRim")?.resolvedColor(with: self.traitCollection).cgColor
       
        titleField.layer.borderWidth = 1
        
        
        let name = NSLocalizedString("nameGeneral", comment: "GeneralViewController")
        titleField.attributedPlaceholder = NSAttributedString(string: name,
                                                              attributes: [NSAttributedString.Key.foregroundColor: UIColor(named: "Gray5")])
        
        titleField.backgroundColor = UIColor(named: "PureBlank")
        descriptionView.backgroundColor = UIColor(named: "PureBlank")
        
        descriptionView.textColor = UIColor(named: "PureBlack")
        matchesHeader.clipsToBounds = true
        matchesHeader.layer.cornerRadius = 8
        matchesHeader.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        
        tableBottomView.layer.cornerRadius = 8
        tableBottomView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        bottomActionView.layer.cornerRadius = 8
        
        descDoneButton.layer.cornerRadius = 6
        titlesDoneButton.layer.cornerRadius = 6
        
        contentsDoneButton.layer.cornerRadius = 6
        
        placeholderLabel = UILabel()
        
        let shortDescription = NSLocalizedString("shortDescriptionPlaceholder", comment: "GeneralViewController")
        
        
        placeholderLabel.text = shortDescription
        placeholderLabel.font = UIFont.systemFont(ofSize: (descriptionView.font?.pointSize)!)
        placeholderLabel.sizeToFit()
        descriptionView.addSubview(placeholderLabel)
        placeholderLabel.frame.origin = CGPoint(x: 5, y: (descriptionView.font?.pointSize)! / 2)
        placeholderLabel.textColor = UIColor(named: "Gray5")
        placeholderLabel.isHidden = !descriptionView.text.isEmpty
        
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        tableView.isScrollEnabled = false
        registerNotifications()
    }
    
    
    func showWarnings() {
        
    }
}

extension GeneralViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteRow(row: indexPath.row)
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GeneralTableviewCell") as! GeneralTableCell
        cell.changedTextDelegate = self
        cell.matchTextField.text = contents[indexPath.row]
        cell.indexPath = indexPath.row
        if addingNewMatch == true {
            addingNewMatch = false
            cell.matchTextField.becomeFirstResponder()
            cell.overlayView.snp.remakeConstraints{ (make) in
                make.top.equalToSuperview()
                make.left.equalToSuperview()
                make.bottom.equalToSuperview()
                make.width.equalTo(0)
            }
        } else {
            if shouldHighlightRows == true {
                if emptyStringErrors.contains(indexPath.row) {
                    cell.overlayView.backgroundColor = #colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1)
                } else {
                    var thisRowContains = false
                    for intArray in stringToIndexesError.values {
                        if intArray.contains(indexPath.row) {
                            thisRowContains = true
                            break
                        }
                    }
                    
                    if thisRowContains == true {
                        cell.overlayView.backgroundColor = #colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)
                    } else {
                        cell.overlayView.snp.remakeConstraints{ (make) in
                            make.top.equalToSuperview()
                            make.left.equalToSuperview()
                            make.bottom.equalToSuperview()
                            make.width.equalTo(0)
                        }
                        cell.contentView.layoutIfNeeded()
                    }
                }
            }
        }
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
}

extension GeneralViewController: ChangedTextCell {
    
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(notification: NSNotification){
        guard let keyboardFrame = notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        scrollView.contentInset.bottom = view.convert(keyboardFrame.cgRectValue, from: nil).size.height
    }

    @objc private func keyboardWillHide(notification: NSNotification){
        scrollView.contentInset.bottom = 0
    }
    
    func cellPressedDoneButton() {
    }
    
    func textFieldStartedEditing(indexPath: Int) {
        currentIndexPath = indexPath
    }
    func textFieldPressedReturn() {
        addNewRow()
        let origPoint = CGPoint(x: 0, y: (currentIndexPath * 50) + 250)
        
        scrollView.setContentOffset(CGPoint(x: 0, y: (currentIndexPath * 50) + 124), animated: true)
    }
    func textFieldChangedText(indexPath: Int, text: String) {
        contents[indexPath] = text
//        showWarningIcon()
    }
    func textFieldEndedEditing(indexPath: Int, text: String) {
        contents[indexPath] = text
//        checkForErrors(contentsArray: contents)
    }
    
}

extension GeneralViewController: UITextViewDelegate, UITextFieldDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.tag == 10902 {
            placeholderLabel.isHidden = !descriptionView.text.isEmpty
        } else if textView.tag == 10903 {
        }
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.tag == 10901 {
            let untitledName = NSLocalizedString("untitledName", comment: "GeneralViewController def=Untitled")
            name = titleField.text ?? untitledName
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        switch textView.tag {
        case 10902:
            descriptionOfList = descriptionView.text
        default:
            break
        }
    }

}


extension GeneralViewController {
    
    
    
    

    
    func fixDuplicates(completion: @escaping () -> Void ) {
        
        print("dup errors: \(stringToIndexesError)")
        var toDeleteArray = [IndexPath]()
        var toDeleteValues = [Int]()
        for singleDup in stringToIndexesError {
            for value in singleDup.value {
                let newInd = IndexPath(row: value, section: 0)
                toDeleteArray.append(newInd)
                toDeleteValues.append(value)
                //contents.remove(at: value)
            }
        }
        //let indexAnimals = [0, 3, 4]
        contents = contents
            .enumerated()
            .filter { !toDeleteValues.contains($0.offset) }
            .map { $0.element }
        
        tableView.performBatchUpdates({
            self.tableView.deleteRows(at: toDeleteArray, with: .automatic)
        }) { _ in
            completion()
//            self.doneWithEditingGeneral(overrideDone: true)
        }
        
        
        
    }
    
}

extension StringProtocol {
    subscript(_ offset: Int)                     -> Element     { self[index(startIndex, offsetBy: offset)] }
    subscript(_ range: Range<Int>)               -> SubSequence { prefix(range.lowerBound+range.count).suffix(range.count) }
    subscript(_ range: ClosedRange<Int>)         -> SubSequence { prefix(range.lowerBound+range.count).suffix(range.count) }
    subscript(_ range: PartialRangeThrough<Int>) -> SubSequence { prefix(range.upperBound.advanced(by: 1)) }
    subscript(_ range: PartialRangeUpTo<Int>)    -> SubSequence { prefix(range.upperBound) }
    subscript(_ range: PartialRangeFrom<Int>)    -> SubSequence { suffix(Swift.max(0, count-range.lowerBound)) }
}
extension LosslessStringConvertible {
    var string: String { .init(self) }
}
extension BidirectionalCollection {
    subscript(safe offset: Int) -> Element? {
        guard !isEmpty, let i = index(startIndex, offsetBy: offset, limitedBy: index(before: endIndex)) else { return nil }
        return self[i]
    }
}


//extension String {
//  func removeFirstChars(length: Int) -> String {
//        if length <= 0 {
//            return self
//        } else if let to = self.index(self.startIndex, offsetBy: length, limitedBy: self.endIndex) {
//            return self.substring(from: to)
//
//        } else {
//            return ""
//        }
//    }
//}

