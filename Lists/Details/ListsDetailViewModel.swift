//
//  ListsDetailViewModel.swift
//  Find
//
//  Created by A. Zheng (github.com/aheze) on 1/22/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//
    
import Combine
import MobileCoreServices
import SwiftUI

class ListsDetailViewModel: ObservableObject {
    var savedList: List
    var realmModel: RealmModel
    var listUpdated: ((List) -> Void)?
    var listDeleted: ((List) -> Void)?
    @Published var list: EditableList
    
    /// Focus the first word when the view controller appears. For use when the "Add Words" button is pressed on an empty list.
    var focusFirstWord = false
    
    /// if the current color is light or not. Store this to prevent over animations
    var colorIsLight = false
    
    var isEditing = false
    var isEditingChanged: (() -> Void)?
    
    @Published var selectedWords = [EditableWord]()
    
    /// the currently-editing word
    @Published var activeWord: EditableWord?
    
    var keyboardShown = false
    
    /// for updating realm
    var listCancellable: AnyCancellable?
    init(
        list: List,
        listUpdated: ((List) -> Void)?,
        listDeleted: ((List) -> Void)?,
        realmModel: RealmModel
    ) {
        savedList = list
        self.list = EditableList(
            id: savedList.id,
            name: savedList.name,
            desc: savedList.desc,
            icon: savedList.icon,
            color: savedList.color,
            words: savedList.words.map { EditableWord(string: $0) },
            dateCreated: savedList.dateCreated
        )
        
        self.realmModel = realmModel
        self.listUpdated = listUpdated
        self.listDeleted = listDeleted
        
        listCancellable = $list
            .debounce(for: .seconds(ListsDetailConstants.editDebounceDuration), scheduler: RunLoop.main)
            .sink { [weak self] list in
                let newList = list.getList()
                self?.listUpdated?(newList)
            }
    }
    
    var deleteSelected: (() -> Void)?
}

extension ListsDetailViewModel {
    /// The traditional method for rearranging rows in a table view.
    func moveItem(at sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex else { return }
        
        let word = list.words[sourceIndex]
        list.words.remove(at: sourceIndex)
        list.words.insert(word, at: destinationIndex)
    }
    
    /// The method for adding a new item to the table view's data model.
    func addItem(_ string: String, at index: Int) {
        let newWord = EditableWord(string: string)
        list.words.insert(newWord, at: index)
    }
    
    /**
          A helper function that serves as an interface to the data model,
          called by the implementation of the `tableView(_ canHandle:)` method.
     */
    func canHandle(_ session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSString.self)
    }
    
    /**
          A helper function that serves as an interface to the data mode, called
          by the `tableView(_:itemsForBeginning:at:)` method.
     */
    func dragItems(for indexPath: IndexPath) -> [UIDragItem] {
        let word = list.words[indexPath.row].string

        let data = word.data(using: .utf8)
        let itemProvider = NSItemProvider()
  
        itemProvider.registerDataRepresentation(forTypeIdentifier: kUTTypePlainText as String, visibility: .all) { completion in
            completion(data, nil)
            return nil
        }

        return [
            UIDragItem(itemProvider: itemProvider)
        ]
    }
}
