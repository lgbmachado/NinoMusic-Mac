//
//  Binding+Case.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Baptista Machado on 03/08/26.
//

import SwiftUI

extension Binding where Value == String {
    func formattedText(_ mode: CaseKind) -> Binding<String> {
        Binding<String>(
            get: { self.wrappedValue },
            set: { newValue in
                switch mode {
                case .uppercase:
                    self.wrappedValue = newValue.uppercased()
                case .lowercase:
                    self.wrappedValue = newValue.lowercased()
                case .capitalized:
                    self.wrappedValue = newValue.capitalized
                case .none:
                    self.wrappedValue = newValue
                }
            }
        )
    }
}
