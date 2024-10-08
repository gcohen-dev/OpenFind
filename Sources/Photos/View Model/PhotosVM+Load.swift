//
//  PhotosVM+Load.swift
//  Find
//
//  Created by A. Zheng (github.com/aheze) on 2/14/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//
    
import Photos
import SwiftUI

extension PhotosViewModel {
    /// only call this once!
    func load() {
        Task {
            if Debug.photosTestEmptyLoading {
                try! await Task.sleep(nanoseconds: 60_000_000_000)
            } else {
                /// this line takes a while to execute
                await self.getRealmModel?().container.loadPhotoMetadatas()
            }
            
            self.loadAssets()
            await self.loadPhotos()
                
            self.sort()
            await self.reloadAfterLoad()
        }
    }
    
    /// Main queue for `@Published`
    @MainActor func reloadAfterLoad() {
        withAnimation {
            loaded = true
        }
        reload?()
        let scan = getRealmModel?().photosScanOnLaunch
        if scan ?? false {
            startScanning()
        }
    }
    
    func loadAssets() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
    }
    
    func getPhotos() async -> ([Photo], [Photo], [Photo]) {
        let photos = await withCheckedContinuation { continuation in
            getPhotos { photos, ignoredPhotos, photosToScan in
                continuation.resume(returning: (photos, ignoredPhotos, photosToScan))
            }
        }
        
        return photos
    }

    /// 1. all photos, 2. ignored photos, 3. photos to scan
    func getPhotos(completion: (([Photo], [Photo], [Photo]) -> Void)?) {
        DispatchQueue.global(qos: .userInitiated).async {
            var photos = [Photo]()
            var ignoredPhotos = [Photo]()
            var photosToScan = [Photo]()
            
            self.assets?.enumerateObjects { [weak self] asset, _, _ in
                
                guard let self = self else { return }
                
                let photo: Photo
                let identifier = asset.localIdentifier
                
                if Debug.photosLoadManyImages {
                    let metadata = PhotoMetadata(
                        assetIdentifier: identifier,
                        isStarred: false,
                        isIgnored: false,
                        dateScanned: Date()
                    )
                    photo = Photo(asset: asset, metadata: metadata)
                } else {
                    if let metadata = self.getRealmModel?().getPhotoMetadata(from: identifier) {
                        photo = Photo(asset: asset, metadata: metadata)
                    
                        if metadata.isIgnored {
                            ignoredPhotos.append(photo)
                        } else if metadata.dateScanned == nil {
                            photosToScan.append(photo)
                        }
                    } else {
                        photo = Photo(asset: asset)
                        photosToScan.append(photo)
                    }
                }
                
                photos.append(photo)
            }
            completion?(photos, ignoredPhotos, photosToScan)
        }
    }
    
    func loadPhotos() async {
        let (photos, ignoredPhotos, photosToScan) = await getPhotos()
        
        await MainActor.run {
            self.photos = photos
            self.ignoredPhotos = ignoredPhotos
            self.photosToScan = photosToScan.reversed()
        }
    }
}
