//
//  Directories.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 17/02/25.
//

import Foundation

class Directories {
    var dirs:[Directory] {
        get {
            let defaults = UserDefaults.standard
            if let dirsData = defaults.data(forKey: "MusicDiretories") {
                let dirs = try! PropertyListDecoder().decode([Directory].self, from: dirsData)
                return dirs
            }
            return [Directory]()
        }
        set {
            let dirsData = try! PropertyListEncoder().encode(newValue)
            let defaults = UserDefaults.standard
            defaults.set(dirsData, forKey: "MusicDiretories")
        }
    }
}

