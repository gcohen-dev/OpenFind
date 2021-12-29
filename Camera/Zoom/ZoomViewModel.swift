//
//  ZoomViewModel.swift
//  Camera
//
//  Created by Zheng on 11/20/21.
//  Copyright © 2021 Andrew. All rights reserved.
//

import SwiftUI

struct ZoomFactor: Hashable {
    /// range of the zoom label (what the user sees)
    /// example: `0.5...1`
    var zoomLabelRange: ClosedRange<CGFloat>
    
    /// 0 = aspect fit
    /// 1 = aspect fill
    var aspectRatioRange: ClosedRange<CGFloat>
    
    /// range of actual zoom
    /// example: `1...2`
    var zoomRange: ClosedRange<CGFloat>
    
    /// position relative to entire slider
    /// example: `0.0..<0.3`
    var positionRange: ClosedRange<CGFloat>
    
    var activationProgress: CGFloat = 1
}

class ZoomViewModel: ObservableObject {
    @Published var ready = false
    @Published var zoomLabel: CGFloat = 1
    @Published var zoom: CGFloat = 2
    
    /// 0 = aspect fit
    /// 1 = aspect fill
    @Published var aspectProgress: CGFloat = 0
    
    @Published var isExpanded = false
    @Published var savedExpandedOffset = CGFloat(0)
    
    @Published var gestureStarted = false
    @Published var keepingExpandedUUID: UUID?
    
    var allowingButtonPresses = true
    var sliderWidth = CGFloat(0)
    var sliderLeftPadding = CGFloat(0)
    
    var containerView: UIView
    init(containerView: UIView) {
        self.containerView = containerView

        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            let previousSliderWidth = self.sliderWidth
            let previousProgress = -self.savedExpandedOffset / previousSliderWidth

            self.updateSliderWidth()
            self.updateSliderLeftPadding()
            
            /// recalculate percent offset based on new screen width
            let savedExpandedOffset = -previousProgress * self.sliderWidth
            self.savedExpandedOffset = savedExpandedOffset
        }
    }
    
    func configureZoomFactors(minZoom: CGFloat, maxZoom: CGFloat, switchoverFactors: [NSNumber]) {
        let limitedMaxZoom = min(40, maxZoom)
        
        let minimumFactorLabel = 0.5
        let centerFactorLabel: Double = 1
        let maxFactorLabel: Double = UIDevice.modelName.contains("iPhone 13 Pro") ? 3 : 2
        let maxZoomLabel: Double = 10

        let zoomLabelRanges: [ClosedRange<CGFloat>] = [
            minimumFactorLabel...centerFactorLabel.nextDown,
            centerFactorLabel...maxFactorLabel.nextDown,
            maxFactorLabel...maxZoomLabel
        ]
        let positionRanges: [ClosedRange<CGFloat>] = [
            0...0.3,
            0.3.nextUp...0.6,
            0.6.nextUp...1
        ]
        var aspectRatioRanges: [ClosedRange<CGFloat>] = []
        var zoomRanges: [ClosedRange<CGFloat>] = []
        
        let cameraCount = switchoverFactors.count + 1
        switch cameraCount {
        case 1:
            aspectRatioRanges = [
                0...1.nextDown,
                1...1,
                1...1
            ]
            zoomRanges = [
                minZoom...1,
                1...2.nextDown,
                2...limitedMaxZoom
            ]
        case 2:
            aspectRatioRanges = [
                0...1.nextDown,
                1...1,
                1...1
            ]
            
            let switchoverFactor1 = Double(truncating: switchoverFactors[0])
            
            zoomRanges = [
                minZoom...1,
                1...switchoverFactor1.nextDown,
                switchoverFactor1...limitedMaxZoom
            ]
        case 3:
            aspectRatioRanges = [
                0...1.nextDown,
                1...1,
                1...1
            ]
            
            let switchoverFactor1 = Double(truncating: switchoverFactors[0])
            let switchoverFactor2 = Double(truncating: switchoverFactors[1])
            
            zoomRanges = [
                minZoom...switchoverFactor1.nextDown,
                switchoverFactor1...switchoverFactor2.nextDown,
                switchoverFactor2...limitedMaxZoom
            ]
        default:
            break
        }
        
        var zoomFactors = [ZoomFactor]()
        for index in zoomRanges.indices {
            let zoomFactor = ZoomFactor(
                zoomLabelRange: zoomLabelRanges[index],
                aspectRatioRange: aspectRatioRanges[index],
                zoomRange: zoomRanges[index],
                positionRange: positionRanges[index]
            )
            zoomFactors.append(zoomFactor)
        }
        
        zoomLabel = centerFactorLabel
        zoom = zoomRanges[1].lowerBound
        C.zoomFactors = zoomFactors
        setup()
        
        ready = true
    }
    
    func setup() {
        updateSliderWidth()
        updateSliderLeftPadding()
        
        savedExpandedOffset = -(C.zoomFactors[safe: 1]?.positionRange.lowerBound ?? 0) * sliderWidth
        
        /// This will be from 0 to 1, from slider leftmost to slider rightmost
        let positionInSlider = positionInSlider(totalOffset: savedExpandedOffset)
        setZoom(positionInSlider: positionInSlider)
        updateActivationProgress(positionInSlider: positionInSlider)
    }
    
    /// return (`totalExpandedOffset`, `newTranslation`)
    func update(translation: CGFloat, ended: Bool, changeDraggingAmount: (CGFloat, CGFloat) -> Void) {
        let offset = savedExpandedOffset + translation
        
        var newSavedExpandedOffset = savedExpandedOffset
        
        /// total offset to replace `savedExpandedOffset` AND `draggingAmount`
        var totalExpandedOffset: CGFloat = 0
        var newTranslation: CGFloat = 0
        
        if offset >= 0 {
            totalExpandedOffset = 0
            newSavedExpandedOffset = 0
            newTranslation = 0
        } else if -offset >= sliderWidth {
            totalExpandedOffset = -sliderWidth
            newSavedExpandedOffset = -sliderWidth
            newTranslation = 0
        } else {
            totalExpandedOffset = newSavedExpandedOffset + translation
            newSavedExpandedOffset = savedExpandedOffset
            newTranslation = translation
        }
        
        /// This will be from 0 to 1, from slider leftmost to slider rightmost
        let positionInSlider = positionInSlider(totalOffset: totalExpandedOffset)
        setZoom(positionInSlider: positionInSlider)
        updateActivationProgress(positionInSlider: positionInSlider)
        expand()

        if ended {
            changeDraggingAmount(totalExpandedOffset, newTranslation)
        } else {
            changeDraggingAmount(newSavedExpandedOffset, newTranslation)
        }
    }
    
    /// width of the entire slider
    func updateSliderWidth() {
        var width = CGFloat(0)
        
        for index in C.zoomFactors.indices {
            let zoomFactor = C.zoomFactors[index]
            
            var addedWidth = CGFloat(0)
            addedWidth += C.zoomFactorLength
            addedWidth += dotViewWidth(for: zoomFactor)
            width += addedWidth
        }
        
        sliderWidth = width
    }
    
    /// have half-screen gap on left side of slider
    func updateSliderLeftPadding() {
        let halfAvailableScreenWidth = availableScreenWidth() / 2
        let halfZoomFactorWidth = C.zoomFactorLength / 2
        let leftPadding = C.edgePadding
        let padding = halfAvailableScreenWidth - halfZoomFactorWidth + leftPadding
        
        sliderLeftPadding = padding
    }
    
    /// width of screen, inset from padding
    func availableScreenWidth() -> CGFloat {
        let availableWidth = UIScreen.main.bounds.width - (C.edgePadding * 2)
        let safeArea = containerView.safeAreaInsets
        let safeAreaHorizontalInset = safeArea.left + safeArea.right
        let containerEdgePadding = C.containerEdgePadding * 2
        return availableWidth - containerEdgePadding - safeAreaHorizontalInset
    }
    
    /// width of a dot view
    func dotViewWidth(for zoomFactor: ZoomFactor) -> CGFloat {
        let availableScreenWidth = availableScreenWidth()
        
        /// remove the width of the rightmost zoom factor
        let rightmostZoomFactorWidth = C.zoomFactorLength
        
        /// **(FACTOR)** OOOOOOOOOO **(FACTOR)** OOOOOOOOOO ~~(removed factor)~~
        /// width for 2 zoom factors and 2 dot views, combined
        /// 2x **(FACTOR)** + 2x OOOOOOOOOO
        let totalContentWidth = availableScreenWidth - rightmostZoomFactorWidth
        
        /// divide by 2, since there are 2 dot views total
        let singleContentWidth = totalContentWidth / 2
        
        /// how much to multiply the width by
        /// `upperBound` - `lowerBound` should either be 0.25 or 0.50.
        let widthMultiplier = (zoomFactor.positionRange.upperBound - zoomFactor.positionRange.lowerBound) / C.normalPositionRange
        
        /// minus `zoomFactorLength` from the content, so it's only the dot view now
        let finalWidth = (singleContentWidth * widthMultiplier) - C.zoomFactorLength
        return finalWidth
    }
    
    /// offset for the active zoom factor
    func activeZoomFactorOffset(for zoomFactor: ZoomFactor, totalOffset: CGFloat) -> CGFloat {
        let position = zoomFactor.positionRange.lowerBound * sliderWidth
        
        /// `totalOffset` is negative, make positive, then subtract `position`
        let offset = -totalOffset - position
        return offset
    }
    
    func updateActivationProgress(positionInSlider: CGFloat) {
        for index in C.zoomFactors.indices {
            let zoomFactor = C.zoomFactors[index]
            let lower = zoomFactor.positionRange.lowerBound

            var percentActivated = CGFloat(1)
            if positionInSlider < lower {
                let distanceToActivation = min(C.activationStartDistance, lower - positionInSlider)
                percentActivated = 1 - (C.activationStartDistance - distanceToActivation) / C.activationRange
            } else if zoomFactor.positionRange.contains(positionInSlider) {
                let distanceToActivation = min(C.activationStartDistance, positionInSlider - lower)
                percentActivated = 1 - (C.activationStartDistance - distanceToActivation) / C.activationRange
            }
            C.zoomFactors[index].activationProgress = max(0.001, percentActivated)
        }
    }
    
    /// from 0 to 1, from slider leftmost to slider rightmost
    func positionInSlider(totalOffset: CGFloat) -> CGFloat {
        let sliderTotalTrackWidth = sliderWidth
        
        /// drag finger left = negative `draggingProgress
        /// so, make `draggingProgress` positive
        let positionInSlider = -totalOffset / sliderTotalTrackWidth
        return positionInSlider
    }
    
    func setZoom(positionInSlider: CGFloat) {
        /// get the zoom factor whose position contains the fraction
        if let zoomFactor = C.zoomFactors.first(where: { $0.positionRange.contains(positionInSlider) }) {
            let positionRangeLower = zoomFactor.positionRange.lowerBound
            let positionRangeUpper = zoomFactor.positionRange.upperBound
            
            /// `positionInSlider` is starts all the way from the left of the entire slider, need to start it from the position range
            let positionInRange = positionInSlider - positionRangeLower
            let fractionOfPositionRange = positionInRange / (positionRangeUpper - positionRangeLower)
            
            /// example: `0.5..<1.0` becomes `0.5`
            let zoomRangeWidth = zoomFactor.zoomRange.upperBound - zoomFactor.zoomRange.lowerBound
            let newZoom = zoomFactor.zoomRange.lowerBound + fractionOfPositionRange * zoomRangeWidth
            
            let aspectRatioWidth = zoomFactor.aspectRatioRange.upperBound - zoomFactor.aspectRatioRange.lowerBound
            let newAspectRatio = zoomFactor.aspectRatioRange.lowerBound + fractionOfPositionRange * aspectRatioWidth
            
            /// display
            let zoomLabelRangeWidth = zoomFactor.zoomLabelRange.upperBound - zoomFactor.zoomLabelRange.lowerBound
            let newZoomLabel = zoomFactor.zoomLabelRange.lowerBound + fractionOfPositionRange * zoomLabelRangeWidth
            let previousZoomLabel = zoomLabel
            
            let roundedPreviousZoomLabel = Double(previousZoomLabel).truncate(places: 1)
            let roundedNewZoomLabel = Double(newZoomLabel).truncate(places: 1)
            
            if
                roundedNewZoomLabel != roundedPreviousZoomLabel,
                floor(roundedNewZoomLabel) == roundedNewZoomLabel || roundedNewZoomLabel == C.zoomFactors[0].zoomLabelRange.lowerBound
            {
                let generator = UISelectionFeedbackGenerator()
                generator.prepare()
                generator.selectionChanged()
            }
            
            DispatchQueue.main.async {
                self.zoom = newZoom
                self.zoomLabel = newZoomLabel
                self.aspectProgress = newAspectRatio
            }
        }
    }
    
    func stopButtonPresses() {
        /// temporary stop button presses to prevent conflicts with the gestures
        DispatchQueue.main.async {
            self.allowingButtonPresses = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.allowingButtonPresses = true
            }
        }
    }

    func expand() {
        if !gestureStarted {
            DispatchQueue.main.async {
                self.keepingExpandedUUID = UUID()
                self.gestureStarted = true
            }
        }
        
        if !isExpanded {
            DispatchQueue.main.async {
                withAnimation(.easeIn(duration: 0.2)) {
                    self.isExpanded = true
                }
            }
        }
    }

    func startTimeout() {
        gestureStarted = false
        let uuidToCheck = keepingExpandedUUID
        DispatchQueue.main.asyncAfter(deadline: .now() + C.timeoutTime) {
            /// make sure another swipe hasn't happened yet
            if uuidToCheck == self.keepingExpandedUUID {
                self.keepingExpandedUUID = nil
                withAnimation {
                    self.isExpanded = false
                }
            }
        }
    }
}
