//
//  PhotosCells.swift
//  Find
//
//  Created by A. Zheng (github.com/aheze) on 2/15/22.
//  Copyright © 2022 A. Zheng. All rights reserved.
//
    
import UIKit

class PhotosCollectionHeader: UICollectionReusableView {
    @IBOutlet var label: UILabel!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var labelLeftC: NSLayoutConstraint!
    @IBOutlet var labelRightC: NSLayoutConstraint! /// space between label right and image right
    @IBOutlet var labelTopC: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        let c = PhotosHeaderConstants.self
        
        label.textColor = .white
        label.font = c.font
        labelLeftC.constant = c.labelLeftPadding
        labelRightC.constant = c.labelRightPadding
        labelTopC.constant = c.labelTopPadding
        
        imageView.image = UIImage(named: "HeaderShadow")
        imageView.contentMode = .scaleToFill
        imageView.clipsToBounds = true
        
        isUserInteractionEnabled = false
    }
    
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        
        if let attributes = layoutAttributes as? PhotosSectionHeaderLayoutAttributes {
            var startTitle = ""
            var endTitle: String?
            if let firstCategorization = attributes.encompassingCategorizations.first {
                startTitle = firstCategorization.getTitle()
            }
            if let endCategorization = attributes.encompassingCategorizations.last {
                endTitle = endCategorization.getTitle()
            }
            
            if let endTitle = endTitle, startTitle != endTitle {
                let title = "\(startTitle) - \(endTitle)"
                label.text = title
            } else {
                label.text = startTitle
            }
            
            self.alpha = attributes.isVisible ? 1 : 0
        }
    }
}

/// the main photos cell
class PhotosCollectionCell: UICollectionViewCell {
    var representedAssetIdentifier: String?
    var tapped: (() -> Void)?
    
    lazy var buttonView = ButtonView()
    lazy var imageView = UIImageView()
    
    lazy var overlayView = UIView()
    lazy var overlayGradientImageView = UIImageView()
    lazy var overlayStarImageView = UIImageView()
    var overlayStarImageViewLeftC: NSLayoutConstraint!
    var overlayStarImageViewBottomC: NSLayoutConstraint!
    
    lazy var selectOverlayView = UIView()
    lazy var selectOverlayIconView = SelectionIconView(configuration: .regular)
    var selectOverlayIconViewRightC: NSLayoutConstraint!
    var selectOverlayIconViewBottomC: NSLayoutConstraint!
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }
    
    func commonInit() {
        let c = PhotosCellConstants.self
        
        addSubview(buttonView)
        buttonView.pinEdgesToSuperview()
        buttonView.addSubview(imageView)
        imageView.pinEdgesToSuperview()
        buttonView.addSubview(overlayView)
        overlayView.isUserInteractionEnabled = false
        overlayView.pinEdgesToSuperview()
        
        overlayView.addSubview(overlayGradientImageView)
        overlayGradientImageView.pinEdgesToSuperview()
        
        overlayView.addSubview(overlayStarImageView)
        overlayStarImageView.translatesAutoresizingMaskIntoConstraints = false
        let overlayStarImageViewLeftC = overlayStarImageView.leadingAnchor.constraint(
            equalTo: overlayView.leadingAnchor,
            constant: c.starLeftPadding
        )
        let overlayStarImageViewBottomC = overlayStarImageView.bottomAnchor.constraint(
            equalTo: overlayView.bottomAnchor,
            constant: -c.starBottomPadding
        )
        NSLayoutConstraint.activate([
            overlayStarImageViewLeftC,
            overlayStarImageViewBottomC
        ])
        self.overlayStarImageViewLeftC = overlayStarImageViewLeftC
        self.overlayStarImageViewBottomC = overlayStarImageViewBottomC
        
        /// setup
        imageView.isUserInteractionEnabled = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        overlayGradientImageView.image = UIImage(named: "CellShadow")
        overlayGradientImageView.isUserInteractionEnabled = false
        overlayGradientImageView.contentMode = .scaleAspectFill
        
        buttonView.tapped = { [weak self] in
            self?.tapped?()
        }
        
        /// configure constants
        overlayView.backgroundColor = .clear
        overlayStarImageView.image = UIImage(systemName: "star.fill")
        overlayStarImageView.tintColor = c.starTintColor
        overlayStarImageView.setIconFont(font: c.starFont)
        
        clipsToBounds = true
        
        // MARK: Selection
        selectOverlayView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        addSubview(selectOverlayView)
        selectOverlayView.pinEdgesToSuperview()
        
        selectOverlayIconView.setState(.hidden)
        selectOverlayView.addSubview(selectOverlayIconView)
        selectOverlayIconView.translatesAutoresizingMaskIntoConstraints = false
        let selectOverlayIconViewRightC = selectOverlayIconView.trailingAnchor.constraint(
            equalTo: selectOverlayView.trailingAnchor,
            constant: -c.selectRightPadding
        )
        let selectOverlayIconViewBottomC = selectOverlayIconView.bottomAnchor.constraint(
            equalTo: selectOverlayView.bottomAnchor,
            constant: -c.selectBottomPadding
        )
        NSLayoutConstraint.activate([
            selectOverlayIconViewRightC,
            selectOverlayIconViewBottomC
        ])
        self.selectOverlayIconViewRightC = selectOverlayIconViewRightC
        self.selectOverlayIconViewBottomC = selectOverlayIconViewBottomC
        selectOverlayView.isUserInteractionEnabled = false
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// the results photos cell
class PhotosResultsCell: UICollectionViewCell {
    var highlightsViewController: HighlightsViewController?
    var representedAssetIdentifier: String?
    
    var tapped: (() -> Void)?
    var appeared: (() -> Void)?
    var disappeared: (() -> Void)?
    @IBOutlet var buttonView: ButtonView!
    
    /// `imageView` on left, `rightStackView` on right
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var stackViewTopC: NSLayoutConstraint!
    @IBOutlet var stackViewRightC: NSLayoutConstraint!
    @IBOutlet var stackViewBottomC: NSLayoutConstraint!
    @IBOutlet var stackViewLeftC: NSLayoutConstraint!
    
    /// image on the left
    
    @IBOutlet var leftContainerView: UIView!
    @IBOutlet var leftContainerViewWidthC: NSLayoutConstraint!
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet var leftOverlayView: UIView!
    @IBOutlet var leftOverlayGradientImageView: UIImageView!
    @IBOutlet var leftOverlayStarImageView: UIImageView!
    @IBOutlet var leftOverlayStarImageViewLeftC: NSLayoutConstraint!
    @IBOutlet var leftOverlayStarImageViewBottomC: NSLayoutConstraint!
    
    /// vertical stack view on right
    @IBOutlet var rightStackView: UIStackView!
    
    /// horizontal stack view, contains title + results
    @IBOutlet var rightTopStackView: UIStackView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var resultsLabel: PaddedLabel!
    
    @IBOutlet var descriptionContainerView: UIView!
    @IBOutlet var descriptionHighlightsContainerView: UIView!
    @IBOutlet var descriptionTextView: UITextView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        resultsLabel.layer.cornerRadius = resultsLabel.bounds.height / 2
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        stackView.isUserInteractionEnabled = false
        resultsLabel.clipsToBounds = true
        
        descriptionTextView.contentInset = .zero
        descriptionTextView.textContainerInset = .zero
        descriptionTextView.backgroundColor = .clear
        
        buttonView.tapped = { [weak self] in
            self?.tapped?()
        }
        
        imageView.contentMode = .scaleAspectFill
        descriptionTextView.isEditable = false
        
        let c = PhotosResultsCellConstants.self
        resultsLabel.backgroundColor = c.resultsLabelBackgroundColor
        resultsLabel.textInsets = c.resultsLabelEdgeInsets
        stackView.spacing = c.cellSpacing
        rightStackView.spacing = c.cellSpacing
        rightTopStackView.spacing = c.cellSpacing
        
        layer.cornerRadius = c.cornerRadius
        leftContainerViewWidthC.constant = c.leftContainerWidth
        
        stackViewTopC.constant = c.cellPadding
        stackViewRightC.constant = c.cellPadding
        stackViewBottomC.constant = c.cellPadding
        stackViewLeftC.constant = c.cellPadding
        
        leftContainerView.clipsToBounds = true
        leftContainerView.layer.cornerRadius = c.leftContainerCornerRadius
        
        titleLabel.font = c.titleFont
        resultsLabel.font = c.resultsFont
        descriptionTextView.font = c.descriptionFont
        
        titleLabel.textColor = c.titleTextColor
        resultsLabel.textColor = c.resultsLabelTextColor
        descriptionTextView.textColor = c.descriptionTextColor
        
        /// configure constants for the image
        leftOverlayView.backgroundColor = .clear
        leftOverlayStarImageView.tintColor = PhotosCellConstants.starTintColor
        leftOverlayStarImageView.setIconFont(font: PhotosCellConstants.starFont)
        leftOverlayStarImageViewLeftC.constant = PhotosCellConstants.starLeftPadding
        leftOverlayStarImageViewBottomC.constant = PhotosCellConstants.starBottomPadding
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        disappeared?()
    }
}
