//
//  AlbunsViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 01/04/25.
//

import Foundation
import SwiftData
import SwiftUI

class AlbunsViewModel: BaseViewModel {
    @Published var albuns: [Album] = []
    @Published var covers: [AlbumCover] = []
    @Published var idAlbumSelected: Album.ID = UUID()
    @Published var filePathCover: String = String()
    @Published var albumSelected: Album = Album.emptyAlbum
    @Published var indexAlbumSelected: Int = 0 {
        didSet {
            if indexAlbumSelected >= 0 && indexAlbumSelected < self.albuns.count {
                let selected = self.albuns[indexAlbumSelected]
                self.idAlbumSelected = selected.id
                self.albumSelected = selected
                self.filePathCover = self.albumSelected.musics.first?.filePath ?? ""
            }
        }
    }
    
    override func onNavigateMusics(kind: NavigationKind, originNotification: MusicContentViewType?) {
        if originNotification == .albuns {
            let searchCount = kind == .next ? musicSelected.seq + 1 : musicSelected.seq - 1
            if let selected = self.albumSelected.musics.first(where: {$0.seq == searchCount}) {
                self.idMusicSelected = selected.id
                self.setIdSelection(selection: self.idMusicSelected ?? UUID())
                musicPlayerViewModel.setMusicSelected(music: self.musicSelected)
                musicPlayerViewModel.originCurrentMusic = .albuns
            }
        }
    }

    func setIdSelection(selection: UUID) {
        for album in albuns {
            if let item = album.musics.first(where: { $0.id == selection }) {
                self.musicSelected.id = item.id
                self.musicSelected.seq = item.seq
                self.musicSelected.artist = album.artist
                self.musicSelected.album = album.album
                self.musicSelected.year = album.year
                self.musicSelected.track = item.track
                self.musicSelected.musicTitle = item.musicTitle
                self.musicSelected.genre = album.genre
                self.musicSelected.duration = item.duration
                self.musicSelected.filePath = item.filePath
            }
        }
    }
    
    func reloadAlbuns() {
        let descriptor = FetchDescriptor<Album>(
            sortBy: [
                SortDescriptor(\.album),
                SortDescriptor(\.artist),
                SortDescriptor(\.year)
            ]
        )
        
        do {
            let fetchedAlbums = try modelContext.fetch(descriptor)
            var seqAlbum = 0
            self.albuns = fetchedAlbums.map { album in
                seqAlbum += 1
                album.seq = seqAlbum
                
                // Ordenar músicas do álbum
                let sortedMusics = album.musics.sorted { music1, music2 in
                    if music1.track != music2.track {
                        return music1.track < music2.track
                    }
                    return music1.musicTitle < music2.musicTitle
                }
                
                var seqMusic = 0
                album.musics = sortedMusics.map { music in
                    seqMusic += 1
                    music.seq = seqMusic
                    return music
                }
                
                return album
            }
            self.covers.removeAll()
            for album in self.albuns {
                let id = album.id
                var image = NSImage()
                if let pathCover = album.musics.first?.filePath {
                    image = Id3TagUtils.getImageCover(path: pathCover) ?? NSImage()
                }
                self.covers.append(AlbumCover(id: id,
                                              cover: Image(nsImage: image)))
            }
        } catch {
            print("Erro ao buscar álbuns: \(error)")
            self.albuns = []
        }
    }
}

