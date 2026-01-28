//
//  Artist.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 01/09/25.
//

import Foundation
import ID3TagEditor
import SwiftUI
import SwiftData

@Model
final class Artist {
    @Attribute(.unique) var id: UUID
    var seq: Int
    var artist: String
    var genre: String
    @Relationship(deleteRule: .cascade) var albuns: [ArtistAlbum]
    
    init(id: UUID = UUID(), seq: Int = 0, artist: String = "", genre: String = "", albuns: [ArtistAlbum] = []) {
        self.id = id
        self.seq = seq
        self.artist = artist
        self.genre = genre
        self.albuns = albuns
    }
    
    static let emptyArtist = Artist()
}

@Model
final class ArtistAlbum {
    @Attribute(.unique) var id: UUID
    var seq: Int
    var album: String
    var year: String
    @Relationship(deleteRule: .cascade) var musics: [ArtistMusic]
    
    init(id: UUID = UUID(), seq: Int = 0, album: String = "", year: String = "", musics: [ArtistMusic] = []) {
        self.id = id
        self.seq = seq
        self.album = album
        self.year = year
        self.musics = musics
    }
    
    static let emptyAlbum = ArtistAlbum()
}

@Model
final class ArtistMusic {
    @Attribute(.unique) var id: UUID
    var seq: Int
    var idServer: Int
    var track: Int
    var musicTitle: String
    var duration: Int
    var filePath: String
    
    init(id: UUID = UUID(), seq: Int = 0, idServer: Int = 0, track: Int = 0, musicTitle: String = "", duration: Int = 0, filePath: String = "") {
        self.id = id
        self.seq = seq
        self.idServer = idServer
        self.track = track
        self.musicTitle = musicTitle
        self.duration = duration
        self.filePath = filePath
    }
    
    static let emptyMusic = ArtistMusic()
}

