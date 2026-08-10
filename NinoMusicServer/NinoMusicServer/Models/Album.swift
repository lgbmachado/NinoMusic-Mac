//
//  Album.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 01/04/25.
//

import Foundation
import SwiftUI

struct Album: Encodable, Decodable, Identifiable {
    var id = UUID()
    var seq: Int
    var album: String
    var artist: String
    var year: Int
    var genre: String
    var musics: [AlbumMusic] = []
    
    enum CodingKeys: String, CodingKey {
        case seq = "seq"
        case album = "album"
        case artist = "artist"
        case year = "year"
        case genre = "genre"
        case musics = "musics"
    }
    
    static let emptyAlbum = Album(seq: 0,
                                  album: String(),
                                  artist: String(),
                                  year: Int(),
                                  genre: String(),
                                  musics: [AlbumMusic]())
}

struct AlbumMusic: Encodable, Decodable, Identifiable {
    var id = UUID()
    var seq: Int
    var idServer: Int
    var track: Int
    var musicTitle: String
    let duration: Int
    var filePath: String
    var hasLyric: Bool
    
    enum CodingKeys: String, CodingKey {
        case seq = "seq"
        case idServer = "idServer"
        case track = "track"
        case musicTitle = "musicTitle"
        case duration = "duration"
        case filePath = "filePath"
        case hasLyric = "hasLyric"
    }
    
    static let emptyMusic = AlbumMusic(seq: Int(),
                                       idServer: Int(),
                                       track: Int(),
                                       musicTitle: String(),
                                       duration: Int(),
                                       filePath: String(),
                                       hasLyric: false)
}
