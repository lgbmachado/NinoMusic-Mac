//
//  ArtistViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 01/04/24.
//

import Foundation

struct ArtistViewModel {
    private let music: Music
}

extension ArtistViewModel {
    init(_ music: Music) {
        self.music = music
    }
}

extension ArtistViewModel {
    
    var artist: String {
        return self.music.artist ?? ""
    }
    
    var album: String {
        return self.music.album ?? ""
    }
    
    var year: String {
        return self.music.year ?? ""
    }
    
    var track: Int {
        return self.music.track ?? 0
    }
    
    var title: String {
        return self.music.musicTitle ?? ""
    }
    
    var genre: String {
        return self.music.genre ?? ""
    }
    
    var duration: Int {
        return self.music.duration ?? 0
    }
    
    var filePath: String {
        return self.music.filePath ?? ""
    }
}
