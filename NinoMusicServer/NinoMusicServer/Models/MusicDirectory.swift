//
//  MusicDirectory.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import Foundation

struct MusicDirectory: Codable,
                       Identifiable,
                       Hashable {
    var id = UUID()
    let name: String
    let path: String
}
