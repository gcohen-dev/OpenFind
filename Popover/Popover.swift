//
//  Popover.swift
//  Popover
//
//  Created by Zheng on 12/5/21.
//  Copyright © 2021 Andrew. All rights reserved.
//

import SwiftUI

struct Popover: Identifiable, Equatable {
    
    /// should stay private to the popover
    var context: Context

    /// convenience
    var position: Position {
        get {
            context.position
        } set {
            context.position = newValue
        }
    }
    
    var attributes: Attributes
    
    /// the content view
    var view: AnyView
    
    /// background
    var background: AnyView
    
    /// normal init
    init<Content: View>(
        position: Position = Position.absolute(.init()),
        attributes: Attributes = .init(),
        @ViewBuilder view: @escaping () -> Content
    ) {
        let context = Context(position: position)
        self.context = context
        self.attributes = attributes
        self.view = AnyView(view())
        self.background = AnyView(EmptyView())
    }
    
    
    /// for a background view
    init<MainContent: View, BackgroundContent: View>(
        position: Position = Position.absolute(.init()),
        attributes: Attributes = .init(),
        @ViewBuilder view: @escaping () -> MainContent,
        @ViewBuilder background: @escaping () -> BackgroundContent
    ) {
        let context = Context(position: position)
        self.context = context
        self.attributes = attributes
        self.view = AnyView(view())
        self.background = AnyView(background().environmentObject(context))
    }
    
    var id: UUID {
        get {
            context.id
        } set {
            context.id = newValue
        }
    }
    
    static func == (lhs: Popover, rhs: Popover) -> Bool {
        lhs.id == rhs.id
    }
    
    struct Attributes {
        var presentation = Presentation()
        var dismissal = Dismissal()
        
        /// for identifying the popover later. Optional.
        var tag: String?
        
        struct Presentation {
            var animation: Animation? = .default
            var transition: AnyTransition? = .opacity
        }
        struct Dismissal {
            var animation: Animation? = .default
            var transition: AnyTransition? = .opacity
            var mode = DismissMode.whenTappedOutside
            var excludedFrames: (() -> [CGRect]) = { [] }
            
            enum DismissMode {
                case whenTappedOutside
                case none
            }
        }
    }
    
    
    class Context: Identifiable, ObservableObject {
        
        /// id of the popover
        var id = UUID()
        
        /// calculated from SwiftUI. If this is `nil`, the popover is not yet ready.
        @Published public private(set) var size: CGSize?
//        {
//            didSet {
//                if let popoverSize = size {
//                    let popoverFrame = position.popoverFrame(popoverSize: popoverSize)
//                    withAnimation {
//                        frame = popoverFrame
//                    }
//                }
//            }
        //        }
        func setSize(_ size: CGSize?, animation: Animation? = nil) {
            self.size = size
            withAnimation(animation) {
                self.frame = getFrame(from: size)
            }
        }
        
        var position: Position
        
        init(position: Position) {
            self.position = position
        }
        
        @Published var frame = CGRect.zero
        
        func getFrame(from size: CGSize?) -> CGRect {
            var popoverFrame = CGRect.zero
            if let popoverSize = size {
                popoverFrame = position.popoverFrame(popoverSize: popoverSize)
            }
            return popoverFrame
        }
        
        var isReady: Bool {
            return size != nil
//            return true
        }
        
    }
    
    enum Position {
        
        case absolute(Absolute)
        case relative(Relative)
        
        struct Absolute {
            var originFrame: (() -> CGRect) = { .zero }
            
            /// the side of the origin view which the popover is attached to
            var originAnchor = Anchor.bottomLeft
            
            /// the side of the popover that gets attached to the origin
            var popoverAnchor = Anchor.topLeft
        }
        
        struct Relative {
            var containerFrame: (() -> CGRect) = { .zero }
            
            var popoverAnchor = Anchor.bottomLeft
        }
        
        
        enum Anchor {
            case topLeft
            case top
            case topRight
            case right
            case bottomRight
            case bottom
            case bottomLeft
            case left
        }
        
    }
}

/// functions for calculating sizes
extension Popover.Position {
    
    /// get the popover's origin point
    /// `popoverSize` is only used for relative positioning
    func popoverOrigin(popoverSize: CGSize) -> CGPoint {
        switch self {
        case .absolute(let position):
            let originFrame = position.originFrame()
            
            switch position.originAnchor {
            case .topLeft:
                return originFrame.origin
            case .top:
                return CGPoint(
                    x: originFrame.origin.x + originFrame.width / 2,
                    y: originFrame.origin.y
                )
            case .topRight:
                return CGPoint(
                    x: originFrame.origin.x + originFrame.width,
                    y: originFrame.origin.y
                )
            case .right:
                return CGPoint(
                    x: originFrame.origin.x + originFrame.width,
                    y: originFrame.origin.y + originFrame.height / 2
                )
            case .bottomRight:
                return CGPoint(
                    x: originFrame.origin.x + originFrame.width,
                    y: originFrame.origin.y + originFrame.height
                )
            case .bottom:
                return CGPoint(
                    x: originFrame.origin.x + originFrame.width / 2,
                    y: originFrame.origin.y + originFrame.height
                )
            case .bottomLeft:
                return CGPoint(
                    x: originFrame.origin.x,
                    y: originFrame.origin.y + originFrame.height
                )
            case .left:
                return CGPoint(
                    x: originFrame.origin.x + originFrame.width,
                    y: originFrame.origin.y + originFrame.height / 2
                )
            }
        case .relative(let position):
            let containerFrame = position.containerFrame()
            
            switch position.popoverAnchor {
            case .topLeft:
                return CGPoint(
                    x: containerFrame.origin.x,
                    y: 0
                )
            case .top:
                return CGPoint(
                    x: containerFrame.origin.x + containerFrame.width / 2 - popoverSize.width / 2,
                    y: containerFrame.origin.y
                )
            case .topRight:
                return CGPoint(
                    x: containerFrame.origin.x + containerFrame.width - popoverSize.width,
                    y: containerFrame.origin.y
                )
            case .right:
                return CGPoint(
                    x: containerFrame.origin.x + containerFrame.width - popoverSize.width,
                    y: containerFrame.origin.y + containerFrame.height / 2 - popoverSize.height / 2
                )
            case .bottomRight:
                return CGPoint(
                    x: containerFrame.origin.x + containerFrame.width - popoverSize.width,
                    y: containerFrame.origin.y + containerFrame.height - popoverSize.height
                )
            case .bottom:
                return CGPoint(
                    x: containerFrame.origin.x + containerFrame.width / 2 - popoverSize.width / 2,
                    y: containerFrame.origin.y + containerFrame.height - popoverSize.height
                )
            case .bottomLeft:
                return CGPoint(
                    x: containerFrame.origin.x,
                    y: containerFrame.origin.y + containerFrame.height - popoverSize.height
                )
            case .left:
                return CGPoint(
                    x: containerFrame.origin.x,
                    y: containerFrame.origin.y + containerFrame.height / 2 - popoverSize.height / 2
                )
            }
        }
    }
    
    func popoverFrame(popoverSize: CGSize) -> CGRect {
        let popoverOrigin = popoverOrigin(popoverSize: popoverSize)
        let popoverAnchor: Anchor
        
        switch self {
        case .absolute(let position):
            popoverAnchor = position.popoverAnchor
        case .relative(_):
            popoverAnchor = .topLeft /// use top left as origin
        }
        
        switch popoverAnchor {
        case .topLeft:
            return CGRect(
                origin: popoverOrigin,
                size: popoverSize
            )
        case .top:
            return CGRect(
                origin: popoverOrigin - CGPoint(x: popoverSize.width / 2, y: 0),
                size: popoverSize
            )
        case .topRight:
            return CGRect(
                origin: popoverOrigin - CGPoint(x: popoverSize.width, y: 0),
                size: popoverSize
            )
        case .right:
            return CGRect(
                origin: popoverOrigin - CGPoint(x: popoverSize.width, y: popoverSize.height / 2),
                size: popoverSize
            )
        case .bottomRight:
            return CGRect(
                origin: popoverOrigin - CGPoint(x: popoverSize.width, y: popoverSize.height),
                size: popoverSize
            )
        case .bottom:
            return CGRect(
                origin: popoverOrigin - CGPoint(x: popoverSize.width / 2, y: popoverSize.height),
                size: popoverSize
            )
        case .bottomLeft:
            return CGRect(
                origin: popoverOrigin - CGPoint(x: 0, y: popoverSize.height),
                size: popoverSize
            )
        case .left:
            return CGRect(
                origin: popoverOrigin - CGPoint(x: 0, y: popoverSize.height / 2),
                size: popoverSize
            )
        }
    }
}
