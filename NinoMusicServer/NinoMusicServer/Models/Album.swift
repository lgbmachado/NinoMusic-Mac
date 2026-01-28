//
//  Album.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 01/04/25.
//

import Foundation
import ID3TagEditor
import SwiftUI
import SwiftData

@Model
final class Album {
    @Attribute(.unique) var id: UUID
    var seq: Int
    var album: String
    var artist: String
    var year: String
    var genre: String
    @Relationship(deleteRule: .cascade) var musics: [AlbumMusic]
    
    init(id: UUID = UUID(), seq: Int = 0, album: String = "", artist: String = "", year: String = "", genre: String = "", musics: [AlbumMusic] = []) {
        self.id = id
        self.seq = seq
        self.album = album
        self.artist = artist
        self.year = year
        self.genre = genre
        self.musics = musics
    }
    
    static let emptyAlbum = Album()
}

@Model
final class AlbumMusic {
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
    
    static let emptyMusic = AlbumMusic()
}
