// SPDX-License-Identifier: MIT
// Copyright © 2018-2020 WireGuard LLC. All Rights Reserved.

import UIKit

// Shim that picks the internal implementation based on iOS version.
// - `DiffableDataSourceSnapshotBackport` on iOS < 13
// - `NSDiffableDataSourceSnapshot` on iOS 13+
// swiftlint:disable:next generic_type_name
struct DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType> where SectionIdentifierType: Hashable, ItemIdentifierType: Hashable {

    fileprivate enum ImplType {
        @available(iOS 13.0, *)
        typealias UIKitImpl = NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>
        typealias Backport = DiffableDataSourceSnapshotBackport<SectionIdentifierType, ItemIdentifierType>

        // Swift runtime crashes if the .case contains the class that doesn't exist in the given
        // version of iOS even when using `@available` attrbibute.
        case uikit(Any) // NSDiffableDataSourceSnapshot
        case backport(Backport)

        @available(iOS 13.0, *)
        var uikitImpl: UIKitImpl {
            guard case .uikit(let value) = self else { fatalError() }

            // swiftlint:disable:next force_cast
            return value as! UIKitImpl
        }

        @available(iOS 13.0, *)
        mutating func mutateUIKitImpl<T>(_ body: (inout UIKitImpl) -> T) -> T {
            var value = uikitImpl

            let returnValue = body(&value)
            self = .uikit(value)

            return returnValue
        }

        mutating func mutateBackport<T>(_ body: (inout Backport) -> T) -> T {
            guard case .backport(var value) = self else { fatalError() }

            let returnValue = body(&value)
            self = .backport(value)

            return returnValue
        }
    }

    fileprivate var impl: ImplType

    init() {
        if #available(iOS 13.0, *) {
            impl = .uikit(NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>())
        } else {
            impl = .backport(DiffableDataSourceSnapshotBackport())
        }
    }

    @available(iOS 13.0, *)
    init(_ snapshot: NSDiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>) {
        impl = .uikit(snapshot)
    }

    var sectionIdentifiers: [SectionIdentifierType] {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.uikitImpl.sectionIdentifiers
        case .backport(let backport):
            return backport.sectionIdentifiers
        }
    }

    var itemIdentifiers: [ItemIdentifierType] {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.uikitImpl.itemIdentifiers
        case .backport(let backport):
            return backport.itemIdentifiers
        }
    }

    var numberOfSections: Int {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.uikitImpl.numberOfSections
        case .backport(let backport):
            return backport.numberOfSections
        }
    }
    var numberOfItems: Int {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.uikitImpl.numberOfItems
        case .backport(let backport):
            return backport.numberOfItems
        }
    }

    func indexOfSection(_ sectionIdentifier: SectionIdentifierType) -> Int? {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.uikitImpl.indexOfSection(sectionIdentifier)
        case .backport(let backport):
            return backport.indexOfSection(sectionIdentifier)
        }
    }

    func indexOfItem(_ itemIdentifier: ItemIdentifierType) -> Int? {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.uikitImpl.indexOfItem(itemIdentifier)
        case .backport(let backport):
            return backport.indexOfItem(itemIdentifier)
        }
    }

    func itemIdentifiers(inSection section: SectionIdentifierType) -> [ItemIdentifierType] {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.uikitImpl.itemIdentifiers(inSection: section)
        case .backport(let backport):
            return backport.itemIdentifiers(inSection: section)
        }
    }

    func sectionIdentifier(containingItem itemIdentifier: ItemIdentifierType) -> SectionIdentifierType? {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.uikitImpl.sectionIdentifier(containingItem: itemIdentifier)
        case .backport(let backport):
            return backport.sectionIdentifier(containingItem: itemIdentifier)
        }
    }

    func numberOfItems(inSection section: SectionIdentifierType) -> Int {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.uikitImpl.numberOfItems(inSection: section)
        case .backport(let backport):
            return backport.numberOfItems(inSection: section)
        }
    }

    mutating func appendSections(_ sections: [SectionIdentifierType]) {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }

            return impl.mutateUIKitImpl { uikitImpl in
                uikitImpl.appendSections(sections)
            }
        case .backport:
            return impl.mutateBackport { backport in
                backport.appendSections(sections)
            }
        }
    }

    mutating func insertSections(_ sections: [SectionIdentifierType], afterSection: SectionIdentifierType) {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.mutateUIKitImpl { uikitImpl in
                uikitImpl.insertSections(sections, afterSection: afterSection)
            }
        case .backport:
            impl.mutateBackport { backport in
                backport.insertSections(sections, afterSection: afterSection)
            }
        }
    }

    mutating func insertSections(_ sections: [SectionIdentifierType], beforeSection: SectionIdentifierType) {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.mutateUIKitImpl { uikitImpl in
                uikitImpl.insertSections(sections, beforeSection: beforeSection)
            }
        case .backport:
            return impl.mutateBackport { backport in
                backport.insertSections(sections, beforeSection: beforeSection)
            }
        }
    }

    mutating func deleteSections(_ sections: [SectionIdentifierType]) {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.mutateUIKitImpl { uikitImpl in
                uikitImpl.deleteSections(sections)
            }
        case .backport:
            return impl.mutateBackport { backport in
                backport.deleteSections(sections)
            }
        }
    }

    mutating func insertItems(_ items: [ItemIdentifierType], afterItem: ItemIdentifierType) {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.mutateUIKitImpl { uikitImpl in
                uikitImpl.insertItems(items, afterItem: afterItem)
            }
        case .backport:
            return impl.mutateBackport { backport in
                backport.insertItems(items, afterItem: afterItem)
            }
        }
    }

    mutating func insertItems(_ items: [ItemIdentifierType], beforeItem: ItemIdentifierType) {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.mutateUIKitImpl { uikitImpl in
                uikitImpl.insertItems(items, beforeItem: beforeItem)
            }
        case .backport:
            return impl.mutateBackport { backport in
                backport.insertItems(items, beforeItem: beforeItem)
            }
        }
    }

    mutating func appendItems(_ items: [ItemIdentifierType], toSection section: SectionIdentifierType? = nil) {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.mutateUIKitImpl { uikitImpl in
                uikitImpl.appendItems(items, toSection: section)
            }
        case .backport:
            return impl.mutateBackport { backport in
                backport.appendItems(items, toSection: section)
            }
        }
    }

    mutating func deleteItems(_ items: [ItemIdentifierType]) {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.mutateUIKitImpl { uikitImpl in
                uikitImpl.deleteItems(items)
            }
        case .backport:
            return impl.mutateBackport { backport in
                backport.deleteItems(items)
            }
        }
    }

    mutating func deleteAllItems() {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.mutateUIKitImpl { uikitImpl in
                uikitImpl.deleteAllItems()
            }
        case .backport:
            return impl.mutateBackport { backport in
                backport.deleteAllItems()
            }
        }
    }

    mutating func reloadSections(_ sections: [SectionIdentifierType]) {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.mutateUIKitImpl { uikitImpl in
                uikitImpl.reloadSections(sections)
            }
        case .backport:
            return impl.mutateBackport { backport in
                backport.reloadSections(sections)
            }
        }
    }

    mutating func reloadItems(_ items: [ItemIdentifierType]) {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.mutateUIKitImpl { uikitImpl in
                uikitImpl.reloadItems(items)
            }
        case .backport:
            return impl.mutateBackport { backport in
                backport.reloadItems(items)
            }
        }
    }
}

// Methods that are only used by a backport implementation (`TableViewDiffableDataSourceBackport`)
extension DiffableDataSourceSnapshot {
    func tableViewIndexPath(forItemAt itemIndex: Int) -> IndexPath? {
        switch impl {
        case .uikit:
            fatalError("Must not be used with NSDiffableDataSourceSnapshot")
        case .backport(let backport):
            return backport.tableViewIndexPath(forItemAt: itemIndex)
        }
    }

    var sectionIdentifiersForReloading: [SectionIdentifierType] {
        switch impl {
        case .uikit:
            fatalError("Must not be used with NSDiffableDataSourceSnapshot")
        case .backport(let backport):
            return backport.sectionIdentifiersForReloading
        }
    }

    var itemIdentifiersForReloading: [ItemIdentifierType] {
        switch impl {
        case .uikit:
            fatalError("Must not be used with NSDiffableDataSourceSnapshot")
        case .backport(let backport):
            return backport.itemIdentifiersForReloading
        }
    }
}

// Backport of `NSDiffableDataSourceSnapshot` from iOS 13+.
// swiftlint:disable:next generic_type_name
private struct DiffableDataSourceSnapshotBackport<SectionIdentifierType, ItemIdentifierType> where SectionIdentifierType: Hashable, ItemIdentifierType: Hashable {

    private(set) var sectionIdentifiers = [SectionIdentifierType]()
    private(set) var itemIdentifiers = [ItemIdentifierType]()
    private var itemRangeBySection = [Range<Int>]()

    private(set) var sectionIdentifiersForReloading = [SectionIdentifierType]()
    private(set) var itemIdentifiersForReloading = [ItemIdentifierType]()

    // MARK: - Metrics

    var numberOfSections: Int {
        return sectionIdentifiers.count
    }

    var numberOfItems: Int {
        return itemIdentifiers.count
    }

    // MARK: - Items & Sections identification

    func indexOfSection(_ sectionIdentifier: SectionIdentifierType) -> Int? {
        return sectionIdentifiers.firstIndex(of: sectionIdentifier)
    }

    func indexOfItem(_ itemIdentifier: ItemIdentifierType) -> Int? {
        return itemIdentifiers.firstIndex(of: itemIdentifier)
    }

    func itemIdentifiers(inSection section: SectionIdentifierType) -> [ItemIdentifierType] {
        guard let range = rangeOfItems(inSection: section) else { return [] }

        return Array(itemIdentifiers[range])
    }

    func sectionIdentifier(containingItem itemIdentifier: ItemIdentifierType) -> SectionIdentifierType? {
        guard let itemIndex = itemIdentifiers.firstIndex(of: itemIdentifier),
              let sectionIndex = itemRangeBySection.firstIndex(where: { $0.contains(itemIndex) }) else { return nil }

        return sectionIdentifiers[sectionIndex]
    }

    func numberOfItems(inSection section: SectionIdentifierType) -> Int {
        return rangeOfItems(inSection: section)!.count
    }

    // MARK: - Adding or removing sections

    mutating func appendSections(_ sections: [SectionIdentifierType]) {
        sectionIdentifiers.append(contentsOf: sections)
        itemRangeBySection.append(contentsOf: sections.map { _ in (0..<0) })
    }

    mutating func insertSections(_ sections: [SectionIdentifierType], afterSection: SectionIdentifierType) {
        let insertionIndex = sectionIdentifiers.firstIndex(of: afterSection)! + 1

        sectionIdentifiers.insert(contentsOf: sections, at: insertionIndex)
        itemRangeBySection.insert(contentsOf: [Range<Int>].init(repeating: (0..<0), count: sections.count), at: insertionIndex)
    }

    mutating func insertSections(_ sections: [SectionIdentifierType], beforeSection: SectionIdentifierType) {
        let insertionIndex = sectionIdentifiers.firstIndex(of: beforeSection)!

        sectionIdentifiers.insert(contentsOf: sections, at: insertionIndex)
        itemRangeBySection.insert(contentsOf: [Range<Int>].init(repeating: (0..<0), count: sections.count), at: insertionIndex)
    }

    mutating func deleteSections(_ sections: [SectionIdentifierType]) {
        var sectionIndicesToRemove = IndexSet()
        var itemRangesToRemove = [Range<Int>]()
        var itemsRemoved = 0

        for section in sections {
            let index = indexOfSection(section)!
            let range = itemRangeBySection[index]

            sectionIndicesToRemove.insert(index)
            itemsRemoved += range.count

            if !range.isEmpty {
                itemRangesToRemove.append(range)
            }
        }

        itemRangesToRemove.sort { lhs, rhs -> Bool in
            return lhs.startIndex > rhs.startIndex
        }

        for itemRange in itemRangesToRemove {
            itemIdentifiers.removeSubrange(itemRange)
        }

        for index in sectionIndicesToRemove.sorted().reversed() {
            sectionIdentifiers.remove(at: index)
            itemRangeBySection.remove(at: index)
        }

        if let startIndex = sectionIndicesToRemove.sorted().first {
            shiftItemRangeBySection(startingWithSectionAt: startIndex, itemDifference: -itemsRemoved)
        }
    }

    // MARK: - Adding or removing items

    mutating func insertItems(_ items: [ItemIdentifierType], afterItem: ItemIdentifierType) {
        let section = sectionIdentifier(containingItem: afterItem)!
        let sectionIndex = sectionIdentifiers.firstIndex(of: section)!
        let insertionIndex = itemIdentifiers.firstIndex(of: afterItem)! + 1

        let range = itemRangeBySection[sectionIndex]
        let startIndex = range.startIndex
        let endIndex = range.endIndex.advanced(by: items.count)
        itemRangeBySection[sectionIndex] = (startIndex ..< endIndex)

        itemIdentifiers.insert(contentsOf: items, at: insertionIndex)
        shiftItemRangeBySection(startingWithSectionAt: sectionIndex + 1, itemDifference: items.count)
    }

    mutating func insertItems(_ items: [ItemIdentifierType], beforeItem: ItemIdentifierType) {
        let section = sectionIdentifier(containingItem: beforeItem)!
        let sectionIndex = sectionIdentifiers.firstIndex(of: section)!
        let insertionIndex = itemIdentifiers.firstIndex(of: beforeItem)!

        let range = itemRangeBySection[sectionIndex]
        let startIndex = range.startIndex
        let endIndex = range.endIndex.advanced(by: items.count)
        itemRangeBySection[sectionIndex] = (startIndex ..< endIndex)

        itemIdentifiers.insert(contentsOf: items, at: insertionIndex)
        shiftItemRangeBySection(startingWithSectionAt: sectionIndex + 1, itemDifference: items.count)
    }

    mutating func appendItems(_ items: [ItemIdentifierType], toSection section: SectionIdentifierType? = nil) {
        let section = section ?? sectionIdentifiers.first!
        let sectionIndex = sectionIdentifiers.firstIndex(of: section)!
        let itemRange = itemRangeBySection[sectionIndex]
        let newItemRange: Range<Int>

        if itemRange.isEmpty {
            let startIndex = self.nearestItemInsetionIndex(forSectionAt: sectionIndex)
            let endIndex = startIndex + items.count

            newItemRange = (startIndex..<endIndex)
        } else {
            let startIndex = itemRange.startIndex
            let endIndex = itemRange.endIndex.advanced(by: items.count)

            newItemRange = (startIndex..<endIndex)
        }

        itemRangeBySection[sectionIndex] = newItemRange

        itemIdentifiers.insert(contentsOf: items, at: newItemRange.endIndex - items.count)
        shiftItemRangeBySection(startingWithSectionAt: sectionIndex + 1, itemDifference: items.count)
    }

    mutating func deleteItems(_ items: [ItemIdentifierType]) {
        var itemsBySection = [Int: [ItemIdentifierType]]()

        for item in items {
            let parentSection = sectionIdentifier(containingItem: item)!
            let sectionIndex = indexOfSection(parentSection)!

            if var itemsInSection = itemsBySection[sectionIndex] {
                itemsInSection.append(item)
                itemsBySection[sectionIndex] = itemsInSection
            } else {
                itemsBySection[sectionIndex] = [item]
            }
        }

        var itemsRemoved = 0

        for (sectionIndex, items) in itemsBySection {
            let itemIndicesToRemove = items.map { item -> Int in
                return self.indexOfItem(item)!
            }

            for index in itemIndicesToRemove.sorted().reversed() {
                itemIdentifiers.remove(at: index)
            }

            let range = itemRangeBySection[sectionIndex]
            itemRangeBySection[sectionIndex] = (range.startIndex..<range.endIndex - itemIndicesToRemove.count)

            itemsRemoved += itemIndicesToRemove.count
        }

        if let firstSectionIndex = itemsBySection.keys.sorted().first {
            shiftItemRangeBySection(startingWithSectionAt: firstSectionIndex + 1, itemDifference: -itemsRemoved)
        }
    }

    mutating func deleteAllItems() {
        self.itemIdentifiers = []
        self.itemRangeBySection = self.sectionIdentifiers.map { _ in (0..<0) }
    }

    // MARK: - Reloading data

    mutating func reloadSections(_ sections: [SectionIdentifierType]) {
        sectionIdentifiersForReloading.append(contentsOf: sections)
    }

    mutating func reloadItems(_ items: [ItemIdentifierType]) {
        itemIdentifiersForReloading.append(contentsOf: items)
    }

    // MARK: - Private

    private func rangeOfItems(inSection section: SectionIdentifierType) -> Range<Int>? {
        guard let sectionIndex = indexOfSection(section) else { return nil }

        return itemRangeBySection[sectionIndex]
    }

    private func nearestItemInsetionIndex(forSectionAt sectionIndex: Int) -> Int {
        let precedingRange = itemRangeBySection[0 ..< sectionIndex].last { range -> Bool in
            return !range.isEmpty
        }
        return precedingRange?.endIndex ?? 0
    }

    private mutating func shiftItemRangeBySection(startingWithSectionAt startIndex: Int, itemDifference: Int) {
        guard itemDifference != 0 else { return }

        for index in startIndex..<sectionIdentifiers.count {
            let range = itemRangeBySection[index]
            if !range.isEmpty {
                let start = max(range.startIndex + itemDifference, 0)
                let end = range.endIndex + itemDifference

                itemRangeBySection[index] = (start ..< end)
            }
        }
    }
}

// Private methods used by `TableViewDiffableDataSource`
private extension DiffableDataSourceSnapshotBackport {
    func tableViewIndexPath(forItemAt itemIndex: Int) -> IndexPath? {
        guard let sectionIndex = itemRangeBySection.firstIndex(where: { $0.contains(itemIndex) }) else { return nil }

        let range = itemRangeBySection[sectionIndex]
        assert(!range.isEmpty)

        return IndexPath(row: itemIndex - range.startIndex, section: sectionIndex)
    }
}

@available(iOS 13.0, *)
extension UITableViewDiffableDataSource {
    func apply(_ snapshot: DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>, animatingDifferences: Bool = true, completion: (() -> Void)? = nil) {
        apply(snapshot.impl.uikitImpl, animatingDifferences: animatingDifferences, completion: completion)
    }
}
