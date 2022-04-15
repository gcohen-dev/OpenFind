//
//  PhotosVM+Scanning.swift
//  Find
//
//  Created by A. Zheng (github.com/aheze) on 2/20/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import UIKit

extension PhotosViewModel {
    /// a photo was just scanned
    /// if `inBatch`, no need for immediate add - check if the user's finger is touching the screen first
    @MainActor func photoScanned(photo: Photo, sentences: [Sentence], visionOptions: VisionOptions, inBatch: Bool) {
        var newPhoto = photo
        if let metadata = photo.metadata {
            var newMetadata = metadata
            newMetadata.dateScanned = Date()
            newMetadata.sentences = sentences
            newMetadata.scannedInLanguages = visionOptions.recognitionLanguages
            print("Update: \(newMetadata.scannedInLanguages)")
            newPhoto.metadata = newMetadata
            addSentences(of: newPhoto, immediately: !inBatch)
            getRealmModel?().container.updatePhotoMetadata(metadata: newMetadata)
        } else {
            let metadata = PhotoMetadata(
                assetIdentifier: photo.asset.localIdentifier,
                dateScanned: Date(),
                sentences: sentences,
                scannedInLanguages: visionOptions.recognitionLanguages,
                isStarred: false,
                isIgnored: false
            )
            newPhoto.metadata = metadata
            addSentences(of: newPhoto, immediately: !inBatch)
            getRealmModel?().container.updatePhotoMetadata(metadata: metadata)
        }

        photosToScan = photosToScan.filter { $0 != photo }
        resumeScanning()
    }

    func startScanning() {
        scanningState = .scanningAllPhotos
        if let lastPhoto = photosToScan.last {
            var findOptions = FindOptions()
            findOptions.priority = .waitUntilNotBusy
            findOptions.action = .photosScanning
            scanPhoto(lastPhoto, findOptions: findOptions, inBatch: true)
        }
    }

    /// call this after a photo was just scanned
    func resumeScanning() {
        if
            shouldResumeScanning(),
            let lastPhoto = photosToScan.last
        {
            scanningState = .scanningAllPhotos
            var findOptions = FindOptions()
            findOptions.priority = .waitUntilNotBusy
            findOptions.action = .photosScanning
            scanPhoto(lastPhoto, findOptions: findOptions, inBatch: true)
        } else {
            scanningState = .dormant
        }
    }

    func pauseScanning() {
        scanningState = .dormant
    }

    /// scan a photo
    /// `inBatch`: scanning all photos. If true, check `scanningState == .scanningAllPhotos`.
    func scanPhoto(_ photo: Photo, findOptions: FindOptions, inBatch: Bool) {
        Task {
            let image = await getFullImage(from: photo)
            let realmModel = getRealmModel?()
            let languages = await realmModel?.getCurrentRecognitionLanguages(accurateMode: true) ?? [Settings.Values.RecognitionLanguage.english.rawValue]

            if let cgImage = image?.cgImage {
                var visionOptions = VisionOptions()
                visionOptions.level = .accurate
                visionOptions.recognitionLanguages = languages

                let request = await Find.find(in: .cgImage(cgImage), visionOptions: visionOptions, findOptions: findOptions)
                let sentences = Find.getSentences(from: request)

                /// discard value if not scanning and `inBatch` is true
                if !inBatch || scanningState == .scanningAllPhotos {
                    await photoScanned(photo: photo, sentences: sentences, visionOptions: visionOptions, inBatch: inBatch)
                }
            }
        }
    }

    /// true if should resume
    func shouldResumeScanning() -> Bool {
        guard scanningState == .scanningAllPhotos else { return false }

        if photosToScan.isEmpty {
            return false
        }

        if
            let prioritizedAction = Find.prioritizedAction, prioritizedAction != .photosScanning
        {
            return false
        }

        return true
    }

    func getRemainingTime() -> String? {
        guard scannedPhotosCount != totalPhotosCount else { return nil }

        let secondsPerPhoto = CGFloat(1.2)
        let seconds = Int(secondsPerPhoto * CGFloat(photosToScan.count))
        if seconds > 60 {
            let minutes = Int(seconds / 60)
            if minutes == 1 {
                return "~\(minutes) minute left"
            } else {
                return "~\(minutes) minutes left"
            }
        }

        if seconds == 1 {
            return "~\(seconds) second left"
        } else {
            return "~\(seconds) seconds left"
        }
    }
}
