//
//  Artist.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 01/09/25.
//

import Foundation

struct Artist: Encodable, Decodable, Identifiable {
    var id = UUID()
    var seq: Int
    var artist: String
    var genre: String
    var albuns: [ArtistAlbum] = []
    
    enum CodingKeys: String, CodingKey {
        case seq = "seq"
        case artist = "artist"
        case genre = "genre"
        case albuns = "albuns"
    }
    
    static let emptyArtist = Artist(seq: 0,
                                    artist: String(),
                                    genre: String(),
                                    albuns: [ArtistAlbum]())
}

struct ArtistAlbum: Encodable, Decodable, Identifiable {
    var id = UUID()
    var seq: Int
    var album: String
    var year: String
    var musics: [ArtistMusic] = []
    
    enum CodingKeys: String, CodingKey {
        case seq = "seq"
        case album = "album"
        case year = "year"
        case musics = "musics"
    }
    
    static let emptyAlbum = ArtistAlbum(seq: 0,
                                        album: String(),
                                        year: String(),
                                        musics: [ArtistMusic]())
}

struct ArtistMusic: Encodable, Decodable, Identifiable {
    var id = UUID()
    var seq: Int
    var idServer: Int
    var track: Int
    var musicTitle: String
    let duration: Int
    var filePath: String
    
    enum CodingKeys: String, CodingKey {
        case seq = "seq"
        case idServer = "idServer"
        case track = "track"
        case musicTitle = "musicTitle"
        case duration = "duration"
        case filePath = "filePath"
    }
    
    static let emptyMusic = ArtistMusic(seq: Int(),
                                        idServer: Int(),
                                        track: Int(),
                                        musicTitle: String(),
                                        duration: Int(),
                                        filePath: String())
}



