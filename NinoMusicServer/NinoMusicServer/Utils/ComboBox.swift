//
//  ComboBox.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Baptista Machado on 26/02/26.
//

import SwiftUI
import AppKit

struct ComboBox: NSViewRepresentable {
    @Binding var text: String
    var items: [String]
    var placeholder: String? = nil
    
    var isEditable: Bool = true

    func makeNSView(context: Context) -> NSComboBox {
        let comboBox = NSComboBox()
        comboBox.addItems(withObjectValues: items)
        comboBox.delegate = context.coordinator
        comboBox.isEditable = isEditable
        comboBox.placeholderString = placeholder
        return comboBox
    }

    func updateNSView(_ nsView: NSComboBox, context: Context) {
        let currentItems = (0..<nsView.numberOfItems).compactMap { nsView.itemObjectValue(at: $0) as? String }
        if currentItems != items {
            nsView.removeAllItems()
            nsView.addItems(withObjectValues: items)
        }

        if nsView.stringValue != text {
            nsView.stringValue = text
        }

        if nsView.placeholderString != placeholder {
            nsView.placeholderString = placeholder
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSComboBoxDelegate {
        var parent: ComboBox

        init(_ parent: ComboBox) {
            self.parent = parent
        }

        func comboBoxSelectionDidChange(_ notification: Notification) {
            guard let comboBox = notification.object as? NSComboBox else { return }
            let selectedIndex = comboBox.indexOfSelectedItem
            guard parent.items.indices.contains(selectedIndex) else { return }
            let selectedItem = parent.items[selectedIndex]
            parent.text = selectedItem
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let comboBox = obj.object as? NSComboBox else { return }
            parent.text = comboBox.stringValue
        }
    }
}

