// SPDX-License-Identifier: MIT
// Copyright © 2018-2020 WireGuard LLC. All Rights Reserved.

import UIKit

// Shim that picks the internal implementation based on iOS version.
// - `TableViewDiffableDataSourceBackport` on iOS < 13
// - `UITableViewDiffableDataSource` on iOS 13+
// swiftlint:disable:next generic_type_name
class TableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>: NSObject, UITableViewDataSource where SectionIdentifierType: Hashable, ItemIdentifierType: Hashable {

    typealias CellProvider = (UITableView, IndexPath, ItemIdentifierType) -> UITableViewCell?

    private enum ImplType {
        @available(iOS 13.0, *)
        typealias UIKitImpl = UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>

        // Swift runtime crashes if the .case contains the class that doesn't exist in the given
        // version of iOS even when using `@available` attrbibute.
        case uikit(Any) // UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>

        case backport(TableViewDiffableDataSourceBackport<SectionIdentifierType, ItemIdentifierType>)

        @available(iOS 13.0, *)
        var uikitImpl: UIKitImpl {
            guard case .uikit(let value) = self else { fatalError() }

            // swiftlint:disable:next force_cast
            return value as! UIKitImpl
        }
    }

    var defaultRowAnimation: UITableView.RowAnimation = .automatic

    private let impl: ImplType

    init(tableView: UITableView, cellProvider: @escaping CellProvider) {
        if #available(iOS 13.0, *) {
            impl = .uikit(UITableViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>(tableView: tableView, cellProvider: cellProvider))
        } else {
            impl = .backport(TableViewDiffableDataSourceBackport<SectionIdentifierType, ItemIdentifierType>(tableView: tableView, cellProvider: cellProvider))
        }
    }

    func snapshot() -> DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType> {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return DiffableDataSourceSnapshot(impl.uikitImpl.snapshot())
        case .backport(let backport):
            return backport.snapshot()
        }
    }

    func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifierType? {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.uikitImpl.itemIdentifier(for: indexPath)
        case .backport(let backport):
            return backport.itemIdentifier(for: indexPath)
        }
    }

    func indexPath(for itemIdentifier: ItemIdentifierType) -> IndexPath? {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.uikitImpl.indexPath(for: itemIdentifier)
        case .backport(let backport):
            return backport.indexPath(for: itemIdentifier)
        }
    }

    func apply(_ snapshot: DiffableDataSourceSnapshot<SectionIdentifierType, ItemIdentifierType>, animatingDifferences: Bool = true, completion: (() -> Void)? = nil) {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            impl.uikitImpl.apply(snapshot, animatingDifferences: animatingDifferences, completion: completion)
        case .backport(let backport):
            return backport.apply(snapshot, animatingDifferences: animatingDifferences, completion: completion)
        }
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.uikitImpl.numberOfSections(in: tableView)
        case .backport(let backport):
            return backport.numberOfSections(in: tableView)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.uikitImpl.tableView(tableView, numberOfRowsInSection: section)
        case .backport(let backport):
            return backport.tableView(tableView, numberOfRowsInSection: section)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch impl {
        case .uikit:
            guard #available(iOS 13.0, *) else { fatalError() }
            return impl.uikitImpl.tableView(tableView, cellForRowAt: indexPath)
        case .backport(let backport):
            return backport.tableView(tableView, cellForRowAt: indexPath)
        }
    }

    // TODO: proxy other methods from UITableViewDataSource
}

// Backport of `UITableViewDiffableDataSource` from iOS 13+.
private class TableViewDiffableDataSourceBackport<SectionIdentifier, ItemIdentifier>: NSObject, UITableViewDataSource where SectionIdentifier: Hashable, ItemIdentifier: Hashable {

    typealias CellProvider = (UITableView, IndexPath, ItemIdentifier) -> UITableViewCell?

    private weak var tableView: UITableView?
    private let cellProvider: CellProvider
    private var source = DiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier>()

    var defaultRowAnimation: UITableView.RowAnimation = .automatic

    init(tableView: UITableView, cellProvider: @escaping CellProvider) {
        self.tableView = tableView
        self.cellProvider = cellProvider

        super.init()

        // `UITableViewDiffableDataSource` assigns itself as dataSource
        tableView.dataSource = self
    }

    func snapshot() -> DiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier> {
        return source
    }

    func itemIdentifier(for indexPath: IndexPath) -> ItemIdentifier? {
        guard indexPath.section < source.sectionIdentifiers.count else { return nil }

        let sectionIdentifier = source.sectionIdentifiers[indexPath.section]
        let itemIdentifiers = source.itemIdentifiers(inSection: sectionIdentifier)

        guard indexPath.row < itemIdentifiers.count else { return nil }

        return itemIdentifiers[indexPath.row]
    }

    func indexPath(for itemIdentifier: ItemIdentifier) -> IndexPath? {
        guard let itemIndex = source.indexOfItem(itemIdentifier) else { return nil }

        return source.tableViewIndexPath(forItemAt: itemIndex)
    }

    func apply(_ snapshot: DiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier>, animatingDifferences: Bool = true, completion: (() -> Void)? = nil) {
        guard animatingDifferences && tableView?.window != nil else {
            self.source = snapshot
            tableView?.reloadData()
            completion?()
            return
        }

        let sectionChanges = snapshot.sectionIdentifiers.backport_difference(from: source.sectionIdentifiers)
        let itemChanges = snapshot.itemIdentifiers.backport_difference(from: source.itemIdentifiers)

        var sectionInsertions = IndexSet()
        var sectionRemovals = IndexSet()
        var sectionReloads = IndexSet()
        var itemInsertions = [IndexPath]()
        var itemRemovals = [IndexPath]()
        var itemReloads = [IndexPath]()

        for change in sectionChanges {
            switch change {
            case .insert(let offset, _, _):
                sectionInsertions.insert(offset)
            case .remove(let offset, _, _):
                sectionRemovals.insert(offset)
            }
        }

        for change in itemChanges {
            switch change {
            case .insert(let offset, _, _):
                let indexPath = snapshot.tableViewIndexPath(forItemAt: offset)!
                itemInsertions.append(indexPath)
            case .remove(let offset, _, _):
                let indexPath = source.tableViewIndexPath(forItemAt: offset)!
                itemRemovals.append(indexPath)
            }
        }

        for sectionIdentifier in snapshot.sectionIdentifiersForReloading {
            let sectionIndex = snapshot.indexOfSection(sectionIdentifier)!
            sectionReloads.insert(sectionIndex)
        }

        for itemIdentifier in snapshot.itemIdentifiersForReloading {
            let itemIndex = snapshot.indexOfItem(itemIdentifier)!
            let indexPath = snapshot.tableViewIndexPath(forItemAt: itemIndex)!
            itemReloads.append(indexPath)
        }

        guard !sectionChanges.isEmpty || !itemChanges.isEmpty || !sectionReloads.isEmpty || !itemReloads.isEmpty else {
            completion?()
            return
        }

        tableView?.performBatchUpdates({
            let animation = animatingDifferences ? defaultRowAnimation : .none

            self.source = snapshot

            if !sectionRemovals.isEmpty {
                tableView?.deleteSections(sectionRemovals, with: animation)
            }

            if !sectionInsertions.isEmpty {
                tableView?.insertSections(sectionInsertions, with: animation)
            }

            if !sectionReloads.isEmpty {
                tableView?.reloadSections(sectionReloads, with: animation)
            }

            if !itemRemovals.isEmpty {
                tableView?.deleteRows(at: itemRemovals, with: animation)
            }

            if !itemInsertions.isEmpty {
                tableView?.insertRows(at: itemInsertions, with: animation)
            }

            if !itemReloads.isEmpty {
                tableView?.reloadRows(at: itemReloads, with: animation)
            }
        }, completion: { _ in
            completion?()
        })
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return source.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionIdentifier = source.sectionIdentifiers[section]

        return source.numberOfItems(inSection: sectionIdentifier)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let itemIdentifier = self.itemIdentifier(for: indexPath)!

        return cellProvider(tableView, indexPath, itemIdentifier)!
    }
}
