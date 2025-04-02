//
//  AlbunsViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 01/04/25.
//

import Foundation
import ID3TagEditor
import SwiftUI

class AlbunsViewModel: NSObject, ObservableObject {
    
    @Published var albuns: [Album] = []
    @Published var idAlbumSelected: Music.ID = UUID()
    @Published var filePathCover: String = String()
    @Published var albumSelected: Album = Album.emptyAlbum
    
    func reloadAlbuns() {
        self.albuns = MusicFiles().albuns
        self.albumSelected = albuns.first ?? Album.emptyAlbum
        self.idAlbumSelected = albumSelected.id
        self.filePathCover = albumSelected.musics.first?.filePath ?? ""
    }
    
    func goToPreviusAlbum() {
        
    }
    
    func goToNextAlbum() {
        let searchCount = albumSelected.seq  + 1
        if let selected = self.albuns.first(where: {$0.seq == searchCount}) {
            self.idAlbumSelected = selected.id
            self.albumSelected = selected
            self.filePathCover = albumSelected.musics.first?.filePath ?? ""
        }
    }
}

