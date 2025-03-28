//
//  Music.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import Foundation

struct Music: Encodable, Decodable, Identifiable {
    var id = UUID()
    var seq: Int
    var idServer: Int
    var artist: String
    var album: String
    var year: String
    var track: Int
    var musicTitle: String
    var genre: String
    let duration: Int
    var filePath: String
    
    enum CodingKeys: String, CodingKey {
        case seq = "seq"
        case idServer = "idServer"
        case artist = "artist"
        case album = "album"
        case year = "year"
        case track = "track"
        case musicTitle = "musicTitle"
        case genre = "genre"
        case duration = "duration"
        case filePath = "filePath"
    }
    
    static let emptyMusic = Music(seq : Int(),
                                  idServer: Int(),
                                  artist: String(),
                                  album: String(),
                                  year: String(),
                                  track: Int(),
                                  musicTitle: String(),
                                  genre: String(),
                                  duration: Int(),
                                  filePath: String())
}
