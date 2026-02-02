//
//  Music.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import Foundation
import SwiftData

@Model
final class Music:Encodable {
    @Attribute(.unique) var id: UUID
    var seq: Int
    var artist: String
    var album: String
    var year: String
    var track: Int
    var musicTitle: String
    var genre: String
    var duration: Int
    var filePath: String
    var hasLyric: Bool
    
    init(id: UUID = UUID(), seq: Int = 0, idServer: Int = 0, artist: String = "", album: String = "", year: String = "", track: Int = 0, musicTitle: String = "", genre: String = "", duration: Int = 0, filePath: String = "", hasLyric: Bool = false) {
        self.id = id
        self.seq = seq
        self.artist = artist
        self.album = album
        self.year = year
        self.track = track
        self.musicTitle = musicTitle
        self.genre = genre
        self.duration = duration
        self.filePath = filePath
        self.hasLyric = hasLyric
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case seq
        case idServer
        case artist
        case album
        case year
        case track
        case musicTitle
        case genre
        case duration
        case filePath
        case hasLyric
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(seq, forKey: .seq)
        try container.encode(artist, forKey: .artist)
        try container.encode(album, forKey: .album)
        try container.encode(year, forKey: .year)
        try container.encode(track, forKey: .track)
        try container.encode(musicTitle, forKey: .musicTitle)
        try container.encode(genre, forKey: .genre)
        try container.encode(duration, forKey: .duration)
        try container.encode(filePath, forKey: .filePath)
        try container.encode(hasLyric, forKey: .hasLyric)
    }
    
    static let emptyMusic = Music()
}

