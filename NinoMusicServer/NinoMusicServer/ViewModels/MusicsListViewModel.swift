//
//  MusicListViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 02/10/22.
//

import Foundation

struct MusicsListViewModel {
    let musics: [Music]
}

extension MusicsListViewModel {
    
    var numberOfSections: Int {
        return 1
    }
    
    func numberOfRowsInSection(_ section: Int) -> Int {
        return self.musics.count
    }
    
    func musicAtIndex(_ index: Int) -> MusicViewModel {
        let music = self.musics[index]
        return MusicViewModel(music)
    }
    
}
