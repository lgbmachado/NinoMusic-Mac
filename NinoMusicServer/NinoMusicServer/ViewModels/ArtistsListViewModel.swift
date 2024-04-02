//
//  ArtistsListViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 01/04/24.
//

import Foundation

struct ArtistsListViewModel {
    let musics: [Music]
}

extension ArtistsListViewModel {
    
    var numberOfSections: Int {
        return 3
    }
    
    func numberOfRowsInSection(_ section: Int) -> Int {
        return self.musics.count
    }
    
    func artistAtIndex(_ index: Int) -> MusicViewModel {
        let music = self.musics[index]
        return MusicViewModel(music)
    }
    
    func isNewArtist(_ index: Int) -> Bool {
        return index > 0 ? self.musics[index].artist != self.musics[index - 1].artist : true
    }
    
    func isNewAlbum(_ index: Int) -> Bool {
        let newArtist = index > 0 ? self.musics[index].artist != self.musics[index - 1].artist : true
        return index > 0 ? newArtist || self.musics[index].album != self.musics[index - 1].album : true
    }
    
}
