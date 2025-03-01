//
//  Directory.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import Foundation

struct Directory: Codable,
                  Identifiable,
                  Hashable {
    var id = UUID()
    let name: String
    let path: String
    
    static let example = Directory(name: "Dir 1",
                  path: "/Users/nino/Music/Music/Media.localized/Music")
    
    static let examples = [
        Directory(name: "Dir 1",
                  path: "/Users/nino/Music/Music/Media.localized/Music"),
        
        Directory(name: "Dir 2",
                  path: "smb://nino-pc/Transf/Músicas Celular"),
    ]
}
