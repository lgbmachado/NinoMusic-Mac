//
//  Musics.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 27/08/24.
//

import Foundation

class Musics {
    var musics = [Music]()
    var idMusicSelected = UUID()
    
    var musicSelected: Music? {
        get {
            if let item = musics.first(where: { $0.id == idMusicSelected }) {
                return item
            } else {
                return nil
            }
        }
    }
}
