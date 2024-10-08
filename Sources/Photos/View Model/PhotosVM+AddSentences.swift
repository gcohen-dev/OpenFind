//
//  PhotosVM+AddSentences.swift
//  Find
//
//  Created by A. Zheng (github.com/aheze) on 3/16/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//

import UIKit

/**
 Add sentence metadata
 */

/// Separate add from update
extension PhotosViewModel {
    func addSentences(of photo: Photo, immediately: Bool) {
        if immediately {
            applySentenceMetadata(for: photo)
            photosWithQueuedSentencesAdded?([photo])
        } else {
            scheduleUpdate(for: photo)
        }
    }

    func scheduleUpdate(for photo: Photo) {
        photosWithQueuedSentences.append(photo)

        if canUpdateDueToTimeout() {
            if updateAllowed {
                addQueuedSentencesToMetadatas()
            } else {
                updateState = .waitingForPermission
            }
        } else {
            if updateState == nil {
                updateState = .scheduled
                DispatchQueue.main.asyncAfter(deadline: .now() + PhotosConstants.minimumResultsUpdateDuration) {
                    if self.updateAllowed {
                        self.addQueuedSentencesToMetadatas()
                    } else {
                        self.updateState = .waitingForPermission
                    }
                }
            }
        }
    }

    /// update each array's photo metadata to include sentences
    func addQueuedSentencesToMetadatas() {
        updateState = nil

        for photo in photosWithQueuedSentences {
            applySentenceMetadata(for: photo)
        }

        photosWithQueuedSentencesAdded?(photosWithQueuedSentences)
        photosWithQueuedSentences.removeAll()
        lastResultsUpdateTime = Date()
    }

    func applySentenceMetadata(for photo: Photo) {
        /// update main array
        if let index = getIndex(for: photo, in: \.photos) {
            /// if `index` is not nil, just modify the changed properties - prevent overriding other properties that might have changed while the queue was waiting
            photos.applyMetadata(at: index, with: photo.metadata)
        }

        if let indexPath = getIndexPath(for: photo, in: \.displayedSections) {
            displayedSections[indexPath.section].photos.applyMetadata(at: indexPath.item, with: photo.metadata)
        }

        if let indexPath = getIndexPath(for: photo, in: \.allSections) {
            allSections[indexPath.section].photos.applyMetadata(at: indexPath.item, with: photo.metadata)
        }
        if let indexPath = getIndexPath(for: photo, in: \.starredSections) {
            starredSections[indexPath.section].photos.applyMetadata(at: indexPath.item, with: photo.metadata)
        }
        if let indexPath = getIndexPath(for: photo, in: \.screenshotsSections) {
            screenshotsSections[indexPath.section].photos.applyMetadata(at: indexPath.item, with: photo.metadata)
        }

        /// these should only be called when the results are already there/exists (the photo was not added dynamically)
        /// If added dynamically, append inside `findAfterQueuedSentencesUpdate` in `PhotosVC+Update`
        if let resultsState = resultsState {
            if let index = resultsState.getFindPhotoIndex(for: photo, in: \.displayedFindPhotos) {
                self.resultsState?.displayedFindPhotos.applyMetadata(at: index, with: photo.metadata)
            }

            if let index = resultsState.getFindPhotoIndex(for: photo, in: \.allFindPhotos) {
                self.resultsState?.allFindPhotos.applyMetadata(at: index, with: photo.metadata)
            }

            if let index = resultsState.getFindPhotoIndex(for: photo, in: \.starredFindPhotos) {
                self.resultsState?.starredFindPhotos.applyMetadata(at: index, with: photo.metadata)
            }

            if let index = resultsState.getFindPhotoIndex(for: photo, in: \.screenshotsFindPhotos) {
                self.resultsState?.screenshotsFindPhotos.applyMetadata(at: index, with: photo.metadata)
            }
        }

        if
            let slidesState = slidesState,
            let index = slidesState.getSlidesPhotoIndex(photo: photo)
        {
            /// must update `currentPhoto` as well
            if let currentIndex = slidesState.getCurrentIndex() {
                if currentIndex == index {
                    self.slidesState?.currentPhoto?.metadata = photo.metadata
                }
            }
            self.slidesState?.slidesPhotos.applyMetadata(at: index, with: photo.metadata)
        }
    }

    func canUpdateDueToTimeout() -> Bool {
        if let lastResultsUpdateTime = lastResultsUpdateTime {
            /// check if passed minimum duration
            if abs(lastResultsUpdateTime.timeIntervalSinceNow) > PhotosConstants.minimumResultsUpdateDuration {
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }
}
