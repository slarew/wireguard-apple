// SPDX-License-Identifier: MIT
// Copyright © 2018-2020 WireGuard LLC. All Rights Reserved.

import UIKit

class EditableTextCell: UITableViewCell {
    var message: String {
        get {
            return valueTextField.text ?? ""
        }
        set {
            valueTextField.text = newValue
        }
    }

    var placeholder: String? {
        get {
            return valueTextField.placeholder
        }
        set {
            valueTextField.placeholder = newValue
        }
    }

    let valueTextField: UITextField = {
        let valueTextField = UITextField()
        valueTextField.textAlignment = .left
        valueTextField.isEnabled = true
        valueTextField.font = UIFont.preferredFont(forTextStyle: .body)
        valueTextField.adjustsFontForContentSizeCategory = true
        valueTextField.autocapitalizationType = .none
        valueTextField.autocorrectionType = .no
        valueTextField.spellCheckingType = .no
        return valueTextField
    }()

    var onValueBeingEdited: ((EditableTextCell, String) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(valueTextField)
        valueTextField.translatesAutoresizingMaskIntoConstraints = false

        // Reduce the bottom margin by 0.5pt to maintain the default cell height (44pt)
        let bottomAnchorConstraint = contentView.layoutMarginsGuide.bottomAnchor.constraint(equalTo: valueTextField.bottomAnchor, constant: -0.5)
        bottomAnchorConstraint.priority = .defaultLow

        NSLayoutConstraint.activate([
            valueTextField.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            contentView.layoutMarginsGuide.trailingAnchor.constraint(equalTo: valueTextField.trailingAnchor),
            contentView.layoutMarginsGuide.topAnchor.constraint(equalTo: valueTextField.topAnchor),
            bottomAnchorConstraint
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(textFieldDidChangeText(_:)), name: UITextField.textDidChangeNotification, object: valueTextField)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func beginEditing() {
        valueTextField.becomeFirstResponder()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        message = ""
        placeholder = nil
    }

    @objc private func textFieldDidChangeText(_ notification: Notification) {
        onValueBeingEdited?(self, valueTextField.text ?? "")
    }
}
