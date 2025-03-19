//
//  Music.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import Foundation

struct Music: Identifiable {
    var id = UUID()
    var count: Int
    var artist: String
    var album: String
    var year: String
    var track: Int
    var musicTitle: String
    var genre: String
    let duration: Int
    var filePath: String
    
    static let emptyMusic = Music(count : Int(),
                                  artist: String(),
                                  album: String(),
                                  year: String(),
                                  track: Int(),
                                  musicTitle: String(),
                                  genre: String(),
                                  duration: Int(),
                                  filePath: String())
    
}

struct MusicRemote: Encodable{
    let id: Int?
    let artist: String?
    let album: String?
    let year: String?
    let track: Int?
    let musicTitle: String?
    let genre: String?
    let duration: Int?
}
