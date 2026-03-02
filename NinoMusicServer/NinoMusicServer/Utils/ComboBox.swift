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
    
    var isEditable: Bool = true

    func makeNSView(context: Context) -> NSComboBox {
        let comboBox = NSComboBox()
        comboBox.addItems(withObjectValues: items)
        comboBox.delegate = context.coordinator
        comboBox.isEditable = isEditable
        return comboBox
    }

    func updateNSView(_ nsView: NSComboBox, context: Context) {
        // Atualiza a lista se os itens mudarem
        if nsView.numberOfItems != items.count {
            nsView.removeAllItems()
            nsView.addItems(withObjectValues: items)
        }
        // Sincroniza o texto
        if nsView.stringValue != text {
            nsView.stringValue = text
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
            let selectedItem = parent.items[comboBox.indexOfSelectedItem]
            parent.text = selectedItem
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let comboBox = obj.object as? NSComboBox else { return }
            parent.text = comboBox.stringValue
        }
    }
}

