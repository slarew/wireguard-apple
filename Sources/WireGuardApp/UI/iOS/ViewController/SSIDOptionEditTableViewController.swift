// SPDX-License-Identifier: MIT
// Copyright © 2018-2020 WireGuard LLC. All Rights Reserved.

import UIKit
import SystemConfiguration.CaptiveNetwork
import NetworkExtension

protocol SSIDOptionEditTableViewControllerDelegate: class {
    func ssidOptionSaved(option: ActivateOnDemandViewModel.OnDemandSSIDOption, ssids: [String])
}

class SSIDOptionEditTableViewController: UITableViewController {
    private enum Section: Hashable {
        case ssidOption
        case selectedSSIDs
        case addSSIDs
    }

    private struct SSIDEntry: Equatable, Hashable {
        let uuid = UUID().uuidString
        var string: String

        func hash(into hasher: inout Hasher) {
            hasher.combine(uuid)
        }

        static func == (lhs: SSIDEntry, rhs: SSIDEntry) -> Bool {
            return lhs.uuid == rhs.uuid
        }
    }

    private enum Item: Hashable {
        case ssidOption(ActivateOnDemandViewModel.OnDemandSSIDOption)
        case selectedSSID(SSIDEntry)
        case noSSID
        case addConnectedSSID(String)
        case addNewSSID
    }

    weak var delegate: SSIDOptionEditTableViewControllerDelegate?

    private var dataSource: TableViewDiffableDataSource<Section, Item>?

    private let ssidOptionFields: [ActivateOnDemandViewModel.OnDemandSSIDOption] = [
        .anySSID,
        .onlySpecificSSIDs,
        .exceptSpecificSSIDs
    ]

    private var selectedOption: ActivateOnDemandViewModel.OnDemandSSIDOption
    private var selectedSSIDs: [SSIDEntry]
    private var connectedSSID: String?

    init(option: ActivateOnDemandViewModel.OnDemandSSIDOption, ssids: [String]) {
        selectedOption = option
        selectedSSIDs = ssids.map {  SSIDEntry(string: $0) }
        super.init(style: .grouped)
    }

    private func makeCell(for itemIdentifier: Item, at indexPath: IndexPath) -> UITableViewCell? {
        guard let dataSource = self.dataSource else { return nil }

        let sectionIdentifier = dataSource.snapshot().sectionIdentifiers[indexPath.section]
        switch sectionIdentifier {
        case .ssidOption:
            return ssidOptionCell(for: tableView, itemIdentifier: itemIdentifier, at: indexPath)
        case .selectedSSIDs:
            switch itemIdentifier {
            case .noSSID:
                return noSSIDsCell(for: tableView, at: indexPath)
            case .selectedSSID(let ssidEntry):
                return selectedSSIDCell(for: tableView, ssidEntry: ssidEntry, at: indexPath)
            default:
                fatalError()
            }
        case .addSSIDs:
            return addSSIDCell(for: tableView, itemIdentifier: itemIdentifier, at: indexPath)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = tr("tunnelOnDemandSSIDViewTitle")

        dataSource = TableViewDiffableDataSource(tableView: tableView) { [weak self] _, indexPath, item -> UITableViewCell? in
            return self?.makeCell(for: item, at: indexPath)
        }

        tableView.dataSource = self
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableView.automaticDimension

        tableView.register(CheckmarkCell.self)
        tableView.register(EditableTextCell.self)
        tableView.register(TextCell.self)
        tableView.isEditing = true
        tableView.allowsSelectionDuringEditing = true
        tableView.keyboardDismissMode = .onDrag

        updateDataSource()

        updateConnectedSSID()
    }

    private func updateConnectedSSID() {
        getConnectedSSID { [weak self] ssid in
            guard let self = self else { return }

            self.connectedSSID = ssid
            self.updateDataSource()
        }
    }

    private func getConnectedSSID(completionHandler: @escaping (String?) -> Void) {
        #if targetEnvironment(simulator)
        completionHandler("Simulator Wi-Fi")
        #else
        if #available(iOS 14, *) {
            NEHotspotNetwork.fetchCurrent { hotspotNetwork in
                completionHandler(hotspotNetwork?.ssid)
            }
        } else {
            if let supportedInterfaces = CNCopySupportedInterfaces() as? [CFString] {
                for interface in supportedInterfaces {
                    if let networkInfo = CNCopyCurrentNetworkInfo(interface) {
                        if let ssid = (networkInfo as NSDictionary)[kCNNetworkInfoKeySSID as String] as? String {
                            completionHandler(!ssid.isEmpty ? ssid : nil)
                            return
                        }
                    }
                }
            }

            completionHandler(nil)
        }
        #endif
    }

    private func updateDataSource(completion: (() -> Void)? = nil) {
        var snapshot = DiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.ssidOption])
        snapshot.appendItems(ssidOptionFields.map { .ssidOption($0) }, toSection: .ssidOption)

        if selectedOption != .anySSID {
            snapshot.appendSections([.selectedSSIDs, .addSSIDs])

            if selectedSSIDs.isEmpty {
                snapshot.appendItems([.noSSID], toSection: .selectedSSIDs)
            } else {
                snapshot.appendItems(selectedSSIDs.map { .selectedSSID($0) }, toSection: .selectedSSIDs)
            }

            if let connectedSSID = connectedSSID, !selectedSSIDs.contains(where: { $0.string == connectedSSID }) {
                snapshot.appendItems([.addConnectedSSID(connectedSSID)], toSection: .addSSIDs)
            }
            snapshot.appendItems([.addNewSSID], toSection: .addSSIDs)
        }

        dataSource?.apply(snapshot, animatingDifferences: true, completion: completion)
    }

    override func viewWillDisappear(_ animated: Bool) {
        delegate?.ssidOptionSaved(option: selectedOption, ssids: selectedSSIDs.map { $0.string })
    }
}

extension SSIDOptionEditTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource?.numberOfSections(in: tableView) ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource?.tableView(tableView, numberOfRowsInSection: section) ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return dataSource!.tableView(tableView, cellForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard let dataSource = dataSource else { return false }

        let sectionIdentifier = dataSource.snapshot().sectionIdentifiers[indexPath.section]

        switch sectionIdentifier {
        case .ssidOption:
            return false
        case .selectedSSIDs:
            return !selectedSSIDs.isEmpty
        case .addSSIDs:
            return true
        }
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        guard let dataSource = dataSource else { return .none }

        let sectionIdentifier = dataSource.snapshot().sectionIdentifiers[indexPath.section]

        switch sectionIdentifier {
        case .ssidOption:
            return .none
        case .selectedSSIDs:
           return .delete
        case .addSSIDs:
            return .insert
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let dataSource = dataSource else { return nil }

        let sectionIdentifier = dataSource.snapshot().sectionIdentifiers[section]

        switch sectionIdentifier {
        case .ssidOption:
            return nil
        case .selectedSSIDs:
            return tr("tunnelOnDemandSectionTitleSelectedSSIDs")
        case .addSSIDs:
            return tr("tunnelOnDemandSectionTitleAddSSIDs")
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard let dataSource = dataSource else { return }

        let sectionIdentifier = dataSource.snapshot().sectionIdentifiers[indexPath.section]

        switch sectionIdentifier {
        case .ssidOption:
            assertionFailure()

        case .selectedSSIDs:
            assert(editingStyle == .delete)
            selectedSSIDs.remove(at: indexPath.row)
            updateDataSource()

        case .addSSIDs:
            assert(editingStyle == .insert)

            let itemIdentifier = dataSource.itemIdentifier(for: indexPath)
            switch itemIdentifier {
            case .addConnectedSSID(let connectedSSID):
                appendSSID(connectedSSID, beginEditing: false)
            case .addNewSSID:
                appendSSID("", beginEditing: true)
            default:
                fatalError()
            }
        }
    }

    private func ssidOptionCell(for tableView: UITableView, itemIdentifier: Item, at indexPath: IndexPath) -> UITableViewCell {
        guard case .ssidOption(let field) = itemIdentifier else { fatalError() }

        let cell: CheckmarkCell = tableView.dequeueReusableCell(for: indexPath)
        cell.message = field.localizedUIString
        cell.isChecked = selectedOption == field
        cell.isEditing = false
        return cell
    }

    private func noSSIDsCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell: TextCell = tableView.dequeueReusableCell(for: indexPath)
        cell.message = tr("tunnelOnDemandNoSSIDs")
        if #available(iOS 13.0, *) {
            cell.setTextColor(.secondaryLabel)
        } else {
            cell.setTextColor(.gray)
        }
        cell.setTextAlignment(.center)
        return cell
    }

    private func selectedSSIDCell(for tableView: UITableView, ssidEntry: SSIDEntry, at indexPath: IndexPath) -> UITableViewCell {
        let cell: EditableTextCell = tableView.dequeueReusableCell(for: indexPath)
        cell.message = ssidEntry.string
        cell.placeholder = tr("tunnelOnDemandSSIDTextFieldPlaceholder")
        cell.isEditing = true
        cell.onValueBeingEdited = { [weak self] cell, text in
            guard let self = self else { return }

            if let row = self.tableView.indexPath(for: cell)?.row {
                self.selectedSSIDs[row].string = text
                self.updateDataSource()
            }
        }
        return cell
    }

    private func addSSIDCell(for tableView: UITableView, itemIdentifier: Item, at indexPath: IndexPath) -> UITableViewCell {
        let cell: TextCell = tableView.dequeueReusableCell(for: indexPath)
        cell.isEditing = true

        switch itemIdentifier {
        case .addConnectedSSID(let connectedSSID):
            cell.message = tr(format: "tunnelOnDemandAddMessageAddConnectedSSID (%@)", connectedSSID)
        case .addNewSSID:
            cell.message = tr("tunnelOnDemandAddMessageAddNewSSID")
        default:
            fatalError()
        }

        return cell
    }
}

extension SSIDOptionEditTableViewController {
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let sectionIdentifier = dataSource?.snapshot().sectionIdentifiers[indexPath.section] else { return nil }

        switch sectionIdentifier {
        case .ssidOption, .addSSIDs:
            return indexPath
        case .selectedSSIDs:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let dataSource = dataSource else { return }

        tableView.deselectRow(at: indexPath, animated: true)

        let itemIdentifier = dataSource.itemIdentifier(for: indexPath)

        switch itemIdentifier {
        case .ssidOption(let newOption):
            setSSIDOption(newOption)

        case .addConnectedSSID(let connectedSSID):
            appendSSID(connectedSSID, beginEditing: false)

        case .addNewSSID:
            appendSSID("", beginEditing: true)

        default:
            break
        }

    }

    private func appendSSID(_ newSSID: String, beginEditing: Bool) {
        guard let dataSource = dataSource else { return }

        let newEntry = SSIDEntry(string: newSSID)
        selectedSSIDs.append(newEntry)
        updateDataSource {
            let indexPath = dataSource.indexPath(for: .selectedSSID(newEntry))!

            if let cell = self.tableView.cellForRow(at: indexPath) as? EditableTextCell, beginEditing {
                cell.beginEditing()
            }
        }
    }

    private func setSSIDOption(_ ssidOption: ActivateOnDemandViewModel.OnDemandSSIDOption) {
        guard let dataSource = dataSource, ssidOption != selectedOption else { return }

        let prevOption = selectedOption
        selectedOption = ssidOption

        // Manually update cells
        let indexPathForPrevItem = dataSource.indexPath(for: .ssidOption(prevOption))!
        let indexPathForSelectedItem = dataSource.indexPath(for: .ssidOption(selectedOption))!

        if let cell = tableView.cellForRow(at: indexPathForPrevItem) as? CheckmarkCell {
            cell.isChecked = false
        }

        if let cell = tableView.cellForRow(at: indexPathForSelectedItem) as? CheckmarkCell {
            cell.isChecked = true
        }

        updateDataSource()
    }
}
