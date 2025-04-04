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
    @Published var idAlbumSelected: Album.ID = UUID()
    @Published var filePathCover: String = String()
    @Published var idMusicSelected: AlbumMusic.ID = UUID()
    @Published var fileSelected: String = String()
    @Published var musicSelected: AlbumMusic = AlbumMusic.emptyMusic
    @Published var albumSelected: Album = Album.emptyAlbum
    
    func reloadAlbuns() {
        self.albuns = MusicFiles().albuns
        self.albumSelected = albuns.first ?? Album.emptyAlbum
        self.idAlbumSelected = albumSelected.id
        self.filePathCover = albuns.first?.musics.first?.filePath ?? ""
    }
    
    func goToPreviusAlbum() {
        let searchCount = albumSelected.seq  - 1
        if let selected = self.albuns.first(where: {$0.seq == searchCount}) {
            self.idAlbumSelected = selected.id
            self.albumSelected = selected
            self.filePathCover = albumSelected.musics.first?.filePath ?? ""
        }
    }
    
    func goToNextAlbum() {
        let searchCount = albumSelected.seq  + 1
        if let selected = self.albuns.first(where: {$0.seq == searchCount}) {
            self.idAlbumSelected = selected.id
            self.albumSelected = selected
            self.filePathCover = self.albumSelected.musics.first?.filePath ?? ""
        }
    }
}

