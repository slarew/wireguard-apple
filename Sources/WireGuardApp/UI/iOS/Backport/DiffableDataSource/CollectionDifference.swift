// SPDX-License-Identifier: MIT
// Copyright © 2018-2020 WireGuard LLC. All Rights Reserved.

import Foundation

// Backport of `CollectionChange` from iOS 13+
enum CollectionChangeBackport<Element>: CustomDebugStringConvertible, Hashable where Element: Hashable {
    case insert(offset: Int, element: Element, associatedWith: Int?)
    case remove(offset: Int, element: Element, associatedWith: Int?)

    var debugDescription: String {
        switch self {
        case .insert(let index, let element, let associatedWith):
            return "insert(index: \(index), element: \(element), associatedWith: \(String(describing: associatedWith)))"
        case .remove(let index, let element, let associatedWith):
            return "remove(index: \(index), element: \(element), associatedWith: \(String(describing: associatedWith)))"
        }
    }
}

// Backport of `CollectionDifference` from iOS 13+
class CollectionDifferenceBackport<ChangeType> where ChangeType: Hashable {
    typealias Change = CollectionChangeBackport<ChangeType>

    private(set) var insertions: [Change] = []
    private(set) var removals: [Change] = []

    init() {}

    init<T>(_ changes: T) where T: Collection, T.Element == Change {
        for change in changes {
            switch change {
            case .insert:
                insertions.append(change)
            case .remove:
                removals.append(change)
            }
        }
    }
}

extension CollectionDifferenceBackport: Collection {
    public typealias Element = Change

    struct Index: Equatable, Comparable, Hashable {
        fileprivate let offset: Int

        fileprivate init(_ offset: Int) {
            self.offset = offset
        }

        static func == (lhs: Index, rhs: Index) -> Bool {
            return lhs.offset == rhs.offset
        }

        static func < (lhs: Index, rhs: Index) -> Bool {
            return lhs.offset < rhs.offset
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(offset)
        }
    }

    var startIndex: Index {
        return Index(0)
    }

    var endIndex: Index {
        return Index(removals.count + insertions.count)
    }

    func index(after i: Index) -> Index {
        return Index(i.offset + 1)
    }

    func index(before i: Index) -> Index {
        return Index(i.offset - 1)
    }

    subscript(position: Index) -> Element {
        if position.offset < removals.count {
            return removals[removals.count - (position.offset + 1)]
        }
        return insertions[position.offset - removals.count]
    }

    public func formIndex(_ index: inout Index, offsetBy distance: Int) {
        index = Index(index.offset + distance)
    }

    public func distance(from start: Index, to end: Index) -> Int {
        return end.offset - start.offset
    }
}

extension Array where Element: Hashable {
    func backport_difference(from otherCollection: [Element], using cmp: ((Element, Element) -> Bool)? = nil) -> CollectionDifferenceBackport<Element> {
        let cmp = cmp ?? { $0 == $1 }
        return myers(from: otherCollection, to: self, using: cmp)
    }
}
