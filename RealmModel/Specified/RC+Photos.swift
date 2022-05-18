//
//  RC+Photos.swift
//  Find
//
//  Created by A. Zheng (github.com/aheze) on 1/28/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import RealmSwift
import UIKit

extension RealmContainer {
    /// this function takes a while to run, add `await`
    func loadPhotoMetadatas() {
        let realm = try! Realm()

        /// convert realm lists to normal lists
        let realmPhotoMetadatas = realm.objects(RealmPhotoMetadata.self)

        /// this line is very fast actually
        let photoMetadatas = realmPhotoMetadatas.map {
            $0.getPhotoMetadata()
        }

        let assetIdentifierToPhotoMetadata = photoMetadatas.reduce(into: [String: PhotoMetadata]()) {
            $0[$1.assetIdentifier] = $1
        }

        DispatchQueue.main.async {
            self.applyMetadatas(assetIdentifierToPhotoMetadata: assetIdentifierToPhotoMetadata)
        }
    }

    @MainActor func applyMetadatas(assetIdentifierToPhotoMetadata: [String: PhotoMetadata]) {
        if let model = getModel?() {
            model.assetIdentifierToPhotoMetadata = assetIdentifierToPhotoMetadata
        }
    }

    func deleteAllPhotos() {
        let realm = try! Realm()
        let metadatas = realm.objects(RealmPhotoMetadata.self)

        do {
            try realm.write {
                realm.delete(metadatas)
            }
            if let model = getModel?() {
                model.assetIdentifierToPhotoMetadata.removeAll()
            }
        } catch {
            Debug.log("Error deleting all photos: \(error)", .error)
        }
    }

    func deleteAllScannedData() {
        let realm = try! Realm()
        let metadatas = realm.objects(RealmPhotoMetadata.self)

        do {
            try realm.write {
                for metadata in metadatas {
                    metadata.dateScanned = nil
                    metadata.text?.sentences = RealmSwift.List<RealmSentence>()
                    metadata.text?.scannedInLanguages = RealmSwift.List<String>()
                }
            }
            if let model = getModel?() {
                model.assetIdentifierToPhotoMetadata.removeAll()
            }
        } catch {
            Debug.log("Error deleting all scanned data: \(error)", .error)
        }
    }

    /// handles both add or update
    /// if `text` is not nil, also update the text
    /// Make sure to transfer any properties from `PhotoMetadata` to `RealmPhotoMetadata`
    func updatePhotoMetadata(metadata: PhotoMetadata?, text: PhotoMetadataText?) {
        guard let metadata = metadata else {
            Debug.log("No metadata.")
            return
        }

        let realm = try! Realm()

        if let realmMetadata = realm.object(ofType: RealmPhotoMetadata.self, forPrimaryKey: metadata.assetIdentifier) {
            do {
                try realm.write {
                    realmMetadata.isStarred = metadata.isStarred
                    realmMetadata.isIgnored = metadata.isIgnored
                    realmMetadata.dateScanned = metadata.dateScanned

                    if let text = text {
                        print("WRiting text. \(text)")
                        realmMetadata.text = text.getRealmText()
                    }
                }

                if let model = getModel?() {
                    if model.assetIdentifierToPhotoMetadata[metadata.assetIdentifier] != nil {
                        model.assetIdentifierToPhotoMetadata[metadata.assetIdentifier] = metadata
                    }
                }
            } catch {
                Debug.log("Error updating photo metadata: \(error)", .error)
            }
        } else {
            addPhotoMetadata(metadata: metadata, text: text)
        }
    }

    /// call this inside `updatePhotoMetadata`
    private func addPhotoMetadata(metadata: PhotoMetadata, text: PhotoMetadataText?) {
        let text = text?.getRealmText()

        let realmMetadata = RealmPhotoMetadata(
            assetIdentifier: metadata.assetIdentifier,
            isStarred: metadata.isStarred,
            isIgnored: metadata.isIgnored,
            dateScanned: metadata.dateScanned,
            text: text
        )

        let realm = try! Realm()

        do {
            try realm.write {
                realm.add(realmMetadata)
            }

            getModel?()?.assetIdentifierToPhotoMetadata[metadata.assetIdentifier] = metadata
        } catch {
            Debug.log("Error adding photo metadata: \(error)", .error)
        }
    }

    func getText(from identifier: String) -> PhotoMetadataText? {
        let realm = try! Realm()
        if
            let realmMetadata = realm.object(ofType: RealmPhotoMetadata.self, forPrimaryKey: identifier),
            let text = realmMetadata.text?.getPhotoMetadataText()
        {
            return text
        }

        return nil
    }

    /// delete metadata and text
    func deletePhotoMetadata(metadata: PhotoMetadata) {
        let realm = try! Realm()
        if let realmMetadata = realm.object(ofType: RealmPhotoMetadata.self, forPrimaryKey: metadata.assetIdentifier) {
            do {
                try realm.write {
                    realm.delete(realmMetadata)
                }

                if let model = getModel?() {
                    model.assetIdentifierToPhotoMetadata[metadata.assetIdentifier] = nil
                }
            } catch {
                Debug.log("Error deleting metadata: \(error)", .error)
            }
        }
    }
}
