//
//  Music.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import Foundation

struct Music: Identifiable {
    let id = UUID()
    let count: Int
    let artist: String
    let album: String
    let year: String
    let track: Int
    let musicTitle: String
    let genre: String
    let duration: Int
    let filePath: String
    
    static let emptyMusic = Music(count : 0,
                                  artist: "",
                                  album: "",
                                  year: "",
                                  track: 0,
                                  musicTitle: "",
                                  genre: "",
                                  duration: 0,
                                  filePath: "")
    
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
