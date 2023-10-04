//
//  MusicViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 02/10/22.
//

import Foundation

struct MusicViewModel {
    private let music: Music
}

extension MusicViewModel {
    init(_ music: Music) {
        self.music = music
    }
}

extension MusicViewModel {
    
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
