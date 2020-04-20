// Created by eric_horacek on 4/15/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import Foundation

// MARK: - BarCoordinatorProperty

/// A property that can be propagated to the bar coordinators within a bar installer.
public struct BarCoordinatorProperty<Property> {

  // MARK: Lifecycle

  public init<Coordinator>(
    keyPath: ReferenceWritableKeyPath<Coordinator, Property>,
    `default`: @escaping @autoclosure () -> Property,
    function: String = #function)
  {
    self.keyPath = keyPath
    self.default = `default`
    self.function = function
    update = { coordinator, value in
      guard let value = value as? Property else { return }
      (coordinator as? Coordinator)?[keyPath: keyPath] = value
    }
  }

  // MARK: Public

  public let keyPath: AnyKeyPath
  public let function: String
  public let `default`: () -> Property

  // MARK: Internal

  let update: (_ coordinator: AnyObject, _ value: Any) -> Void

  var key: BarCoordinatorPropertyKey {
    .init(keyPath: keyPath, function: function)
  }

}

// MARK: - BarCoordinatorPropertyConfigurable

/// A type that can propagate properties to its coordinators.
public protocol BarCoordinatorPropertyConfigurable {
  subscript<Property>(property: BarCoordinatorProperty<Property>) -> Property { get set }
}

// MARK: - BarCoordinatorPropertyKey

/// A key that uniquely identifies a `BarCoordinatorProperty`.
struct BarCoordinatorPropertyKey: Hashable {
  public var keyPath: AnyKeyPath
  public var function: String
}
