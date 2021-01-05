//  Created by Laura Skelton on 5/19/17.
//  Copyright © 2017 Airbnb. All rights reserved.

import UIKit

/// An internal cell class for use in a `CollectionView`.
public final class CollectionViewCell: UICollectionViewCell, EpoxyCell {

  // MARK: Lifecycle

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Public

  public private(set) var view: UIView?

  public var selectedBackgroundColor: UIColor?

  override public var isSelected: Bool {
    didSet {
      updateVisualHighlightState(isSelected)
    }
  }

  override public var isHighlighted: Bool {
    didSet {
      updateVisualHighlightState(isHighlighted)
    }
  }

  /// Pass a view for this cell's reuseID that the cell will pin to the edges of its `contentView`.
  public func setViewIfNeeded(view: UIView) {
    guard self.view == nil else {
      return
    }

    self.view = view
    normalViewBackgroundColor = view.backgroundColor

    view.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(view)
    NSLayoutConstraint.activate([
      view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      view.topAnchor.constraint(equalTo: contentView.topAnchor),
      view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }

  override public func preferredLayoutAttributesFitting(
    _ layoutAttributes: UICollectionViewLayoutAttributes)
    -> UICollectionViewLayoutAttributes
  {
    guard let fittingPrioritiesProvider = layoutAttributes as? LayoutAttributesFittingPrioritiesProvider else {
      return super.preferredLayoutAttributesFitting(layoutAttributes)
    }

    let horizontalFittingPriority = fittingPrioritiesProvider.horizontalFittingPriority
    let verticalFittingPriority = fittingPrioritiesProvider.verticalFittingPriority

    // In some cases, `contentView`'s required width and height constraints
    // (created from its auto-resizing mask) will not have the correct constants before invoking
    // `systemLayoutSizeFitting(...)`, causing the cell to size incorrectly. This seems to be a
    // UIKit bug.
    // https://openradar.appspot.com/radar?id=5025850143539200
    // The issue seems most common when the collection view's bounds change (on rotation).
    // We correct for this by updating `contentView.bounds`, which updates the constants used by the
    // width and height constraints created by the `contentView`'s auto-resizing mask.

    if
      horizontalFittingPriority == .required &&
      contentView.bounds.width != layoutAttributes.size.width
    {
      contentView.bounds.size.width = layoutAttributes.size.width
    }

    if
      verticalFittingPriority == .required &&
      contentView.bounds.height != layoutAttributes.size.height
    {
      contentView.bounds.size.height = layoutAttributes.size.height
    }

    let size: CGSize
    if horizontalFittingPriority != .required || verticalFittingPriority != .required {
      // Self-sizing is required in at least one dimension.
      size = super.systemLayoutSizeFitting(
        layoutAttributes.size,
        withHorizontalFittingPriority: horizontalFittingPriority,
        verticalFittingPriority: verticalFittingPriority)
    } else {
      // No self-sizing is required; respect whatever size the layout determined.
      size = layoutAttributes.size
    }

    layoutAttributes.size = size

    return layoutAttributes
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    ephemeralViewCachedStateProvider?(cachedEphemeralState)
  }

  // MARK: Internal

  weak var accessibilityDelegate: CollectionViewCellAccessibilityDelegate?
  var ephemeralViewCachedStateProvider: ((RestorableState?) -> ())?

  // MARK: Private

  private var normalViewBackgroundColor: UIColor?

  private func updateVisualHighlightState(_ isVisuallyHighlighted: Bool) {
    if selectedBackgroundColor == nil { return }

    /// This is a temporary solution to support DLSComponentLibrary views that have a background color.
    /// This only works if subviews have a clear background color.
    if isVisuallyHighlighted {
      view?.backgroundColor = selectedBackgroundColor
    } else {
      view?.backgroundColor = normalViewBackgroundColor
    }
  }

}

// MARK: EphemeralViewState

extension CollectionViewCell: EphemeralCachedStateView {
  public var cachedEphemeralState: RestorableState? {
    get { return (view as? EphemeralCachedStateView)?.cachedEphemeralState }
    set { (view as? EphemeralCachedStateView)?.cachedEphemeralState = newValue }
  }
}

// MARK: UIAccessibility

extension CollectionViewCell {
  public override var accessibilityElementsHidden: Bool {
    get {
      if let accessibilityCustomizable = view as? EpoxyAccessibilityCustomizable {
        return accessibilityCustomizable.isHiddenFromVoiceOver
      }
      return super.accessibilityElementsHidden
    }
    set { super.accessibilityElementsHidden = newValue }
  }

  public override func accessibilityElementDidBecomeFocused() {
    super.accessibilityElementDidBecomeFocused()
    accessibilityDelegate?.collectionViewCellDidBecomeFocused(cell: self)
  }

  public override func accessibilityElementDidLoseFocus() {
    super.accessibilityElementDidLoseFocus()
    accessibilityDelegate?.collectionViewCellDidLoseFocus(cell: self)
  }
}
