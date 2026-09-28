//
//  Music.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import Foundation

struct Music: Encodable, Decodable, Identifiable, Equatable {
    var id = UUID()
    var seq: Int
    var idServer: Int
    var artist: String
    var album: String
    var year: Int
    var track: Int
    var musicTitle: String
    var genre: String
    var duration: Int
    var filePath: String
    var hasLyric: Bool
    var isFavorite: Bool
    var lastUpdate: Date
    var lastExecution: Date
    var countExecution: Int
    
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
        case hasLyric = "hasLyric"
        case isFavorite = "isFavorite"
        case lastUpdate = "lastUpdate"
        case lastExecution = "lastExecution"
        case countExecution = "countExecution"
    }
    
    static let emptyMusic = Music(seq : Int(),
                                  idServer: Int(),
                                  artist: String(),
                                  album: String(),
                                  year: Int(),
                                  track: Int(),
                                  musicTitle: String(),
                                  genre: String(),
                                  duration: Int(),
                                  filePath: String(),
                                  hasLyric: false,
                                  isFavorite: false,
                                  lastUpdate: Date(),
                                  lastExecution: Date(),
                                  countExecution: 0)
}
