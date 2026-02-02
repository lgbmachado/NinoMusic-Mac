//
//  ArtistsViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 03/09/25.
//

import Foundation
import SwiftData

struct Node: Identifiable {
    var id: UUID?
    let name: String
    var children: [Node]?
    var musics: [ArtistMusic]?
}

class ArtistsViewModel: BaseViewModel {
    @Published var artists: [Artist] = []
    @Published var idAlbumSelected: UUID? = nil
    @Published var idArtistSelected: Artist.ID? = nil
    @Published var albumSelected: ArtistAlbum = ArtistAlbum.emptyAlbum
    @Published var artistSelected: Artist = Artist.emptyArtist
    
    override func onNavigate(kind: NavigationKind, originNotification: MusicContentViewType?) {
        if originNotification == .artists {
            let searchCount = kind == .next ? musicSelected.seq + 1 : musicSelected.seq - 1
            if let selected = self.albumSelected.musics.first(where: {$0.seq == searchCount}) {
                self.idMusicSelected = selected.id
                self.setIdSelection(selection: self.idMusicSelected ?? UUID())
                musicPlayerViewModel.setMusicSelected(music: self.musicSelected)
                musicPlayerViewModel.originCurrentMusic = .albuns
            }
        }
    }
    
    func getNodes() -> [Node] {
        var nodes = [Node]()
        for artist in self.artists {
            var node = Node(id: artist.id, name: artist.artist)
            node.children = [Node]()
            node.musics = nil
            for album in artist.albuns {
                var subNode = Node(id: album.id, name: album.album)
                subNode.children = nil
                subNode.musics = album.musics
                node.children?.append(subNode)
            }
            nodes.append(node)
        }
        return nodes
    }
    
    func setIdSelection(selection: UUID) {
        for artist in self.artists {
            for album in artist.albuns {
                if let item = album.musics.first(where: { $0.id == selection }) {
                    self.artistSelected = artist
                    self.albumSelected = album
                    
                    self.musicSelected.id = item.id
                    self.musicSelected.seq = item.seq
                    self.musicSelected.artist = artist.artist
                    self.musicSelected.album = album.album
                    self.musicSelected.year = album.year
                    self.musicSelected.track = item.track
                    self.musicSelected.musicTitle = item.musicTitle
                    self.musicSelected.genre = artist.genre
                    self.musicSelected.duration = item.duration
                    self.musicSelected.filePath = item.filePath
                    return
                }
            }
        }
    }
    
    func reloadArtists() {
        let descriptor = FetchDescriptor<Artist>(
            sortBy: [
                SortDescriptor(\.artist)
            ]
        )
        
        do {
            let fetchedArtists = try modelContext.fetch(descriptor)
            var seqArtist = 0
            
            self.artists = fetchedArtists.map { artist in
                seqArtist += 1
                artist.seq = seqArtist
                
                // Ordenar álbuns do artista
                let sortedAlbums = artist.albuns.sorted { album1, album2 in
                    if album1.year != album2.year {
                        return album1.year < album2.year
                    }
                    return album1.album < album2.album
                }
                
                var seqAlbum = 0
                artist.albuns = sortedAlbums.map { album in
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
                
                return artist
            }
        } catch {
            print("Erro ao buscar artistas: \(error)")
            self.artists = []
        }
    }
}
