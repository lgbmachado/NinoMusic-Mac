//
//  Data+Append.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 14/10/22.
//

import Foundation

extension Data {
    mutating func append(_ string: String) {
        self.append(string.data(using: .utf8)!)
    }
}
