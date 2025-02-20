//
//  String.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 20/02/25.
//

import Foundation

extension String {
    func localized() -> String {
        let path = Bundle.main.path(forResource: "your language", ofType: "lproj")!
        if let bundle = Bundle(path: path) {
            let str = bundle.localizedString(forKey: self, value: nil, table: nil)
            return str
        }
        return ""
    }
}
