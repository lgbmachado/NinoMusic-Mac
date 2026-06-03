//
//  ArtistsViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 03/09/25.
//

import Foundation
import SQLite3

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
    
    override func onNavigateMusics(kind: NavigationKind, originNotification: MusicContentViewType?) {
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
    
    func setIdSelection(selection: Music.ID) {
        for artist in self.artists {
            for album in artist.albuns {
                if let item = album.musics.first(where: { $0.id == selection }) {
                    self.artistSelected = artist
                    self.albumSelected = album
                    
                    self.musicSelected.id = item.id
                    self.musicSelected.seq = item.seq
                    self.musicSelected.idServer = item.idServer
                    self.musicSelected.artist = artist.artist
                    self.musicSelected.album = album.album
                    self.musicSelected.year = album.year
                    self.musicSelected.track = item.track
                    self.musicSelected.musicTitle = item.musicTitle
                    self.musicSelected.genre = artist.genre
                    self.musicSelected.duration = item.duration
                    self.musicSelected.filePath = item.filePath
                    self.musicSelected.hasLyric = item.hasLyric
                    return
                }
            }
        }
    }
    
    func reloadArtists() async {
        let sqlArtist = """
    SELECT DISTINCT
       \(DbConstants.TableMusic.colIdArtist),
       \(DbConstants.TableArtist.colArtist),
       \(DbConstants.TableGenre.colGenre)
    FROM
       \(DbConstants.TableMusic.tableName)
       INNER JOIN \(DbConstants.TableArtist.tableName) ON \(DbConstants.TableArtist.tableName).\(DbConstants.TableArtist.colArtistId) = \(DbConstants.TableMusic.colIdArtist)
       INNER JOIN \(DbConstants.TableGenre.tableName) ON \(DbConstants.TableGenre.tableName).\(DbConstants.TableGenre.colGenreId) = \(DbConstants.TableMusic.colIdGenre)
    ORDER BY
       \(DbConstants.TableArtist.colArtist),
       \(DbConstants.TableMusic.colTrack)
    """
        await MainActor.run {
            self.isLoading = true
        }

        let artistList = await withCheckedContinuation { (continuation: CheckedContinuation<[Artist], Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                var artistList = [Artist]()
                var artistAlbumList = [ArtistAlbum]()
                var artistMusicList = [ArtistMusic]()
                var seqArtist = 0
                var seqAlbum = 0
                var seqMusic = 0
                do {
                    if let rowsArtists = try self.helper?.sql(query: sqlArtist) {
                        for rowArtist in rowsArtists {
                            if let idArtist = rowArtist[DbConstants.TableMusic.colIdArtist] as? Int,
                               let artist = rowArtist[DbConstants.TableArtist.colArtist] as? String,
                               let genre = rowArtist[DbConstants.TableGenre.colGenre] as? String
                            {
                                seqArtist += 1
                                let sqlAlbuns = """
                                       SELECT DISTINCT
                                          \(DbConstants.TableAlbum.tableName).\(DbConstants.TableAlbum.colAlbumId),
                                          \(DbConstants.TableAlbum.colAlbum),
                                          \(DbConstants.TableAlbum.colYear)
                                       FROM
                                          \(DbConstants.TableMusic.tableName)
                                          INNER JOIN \(DbConstants.TableArtist.tableName) ON \(DbConstants.TableArtist.tableName).\(DbConstants.TableArtist.colArtistId) = \(DbConstants.TableMusic.colIdArtist)
                                          INNER JOIN \(DbConstants.TableAlbum.tableName) ON \(DbConstants.TableAlbum.tableName).\(DbConstants.TableAlbum.colAlbumId) = \(DbConstants.TableMusic.colIdAlbum)
                                       WHERE
                                          \(DbConstants.TableMusic.colIdArtist) = \(idArtist)
                                       ORDER BY
                                          \(DbConstants.TableAlbum.colYear),
                                          \(DbConstants.TableAlbum.colAlbum)
                                       
                                       """
                                seqAlbum = 0
                                do {
                                    if let rowsAlbuns = try self.helper?.sql(query: sqlAlbuns) {
                                        for rowAlbum in rowsAlbuns {
                                            if let idAlbum = rowAlbum[DbConstants.TableAlbum.colAlbumId] as? Int,
                                               let album = rowAlbum[DbConstants.TableAlbum.colAlbum] as? String,
                                               let year = rowAlbum[DbConstants.TableAlbum.colYear] as? String
                                            {
                                                let sqlMusics = """
                                                         SELECT
                                                            \(DbConstants.TableMusic.colRowId),
                                                            \(DbConstants.TableMusic.colTrack),
                                                            \(DbConstants.TableMusic.colTitle),
                                                            \(DbConstants.TableMusic.colDuration),
                                                            \(DbConstants.TableMusic.colFilePath),
                                                            \(DbConstants.TableMusic.colHasLyrics)
                                                         FROM
                                                            \(DbConstants.TableMusic.tableName)
                                                         WHERE
                                                            \(DbConstants.TableMusic.colIdAlbum) = \(idAlbum) AND 
                                                            \(DbConstants.TableMusic.colIdArtist) = \(idArtist) 
                                                         ORDER BY
                                                            \(DbConstants.TableMusic.colTrack),
                                                            \(DbConstants.TableMusic.colTitle)
                                                         """
                                                do {
                                                    if let rowsMusicsAlbum = try self.helper?.sql(query: sqlMusics) {
                                                        seqMusic = 0
                                                        for rowMusicAlbum in rowsMusicsAlbum {
                                                            if let idServer = rowMusicAlbum[DbConstants.TableMusic.colRowId] as? Int,
                                                               let track = rowMusicAlbum[DbConstants.TableMusic.colTrack] as? Int,
                                                               let musicTitle = rowMusicAlbum[DbConstants.TableMusic.colTitle] as? String,
                                                               let duration = rowMusicAlbum[DbConstants.TableMusic.colDuration] as? Int,
                                                               let filePath = rowMusicAlbum[DbConstants.TableMusic.colFilePath] as? String,
                                                               let hasLyric = rowMusicAlbum[DbConstants.TableMusic.colHasLyrics] as? Int
                                                            {
                                                                seqMusic += 1
                                                                artistMusicList.append(ArtistMusic(seq: seqMusic,
                                                                                                   idServer: idServer,
                                                                                                   track: track,
                                                                                                   musicTitle: musicTitle,
                                                                                                   duration: duration,
                                                                                                   filePath: filePath,
                                                                                                   hasLyric: hasLyric == 1))
                                                            }
                                                        }
                                                        seqAlbum += 1
                                                        artistAlbumList.append(ArtistAlbum(seq: seqAlbum,
                                                                                           album: album,
                                                                                           year: year,
                                                                                           musics: artistMusicList))
                                                        
                                                        artistMusicList.removeAll()
                                                    }
                                                } catch {
                                                    print(error)
                                                }
                                            }
                                        }
                                        artistList.append(Artist(seq: seqArtist,
                                                                 artist: artist,
                                                                 genre: genre,
                                                                 albuns: artistAlbumList))
                                        artistAlbumList.removeAll()
                                    }
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }
                } catch {
                    print(error)
                }

                continuation.resume(returning: artistList)
            }
        }

        await MainActor.run {
            self.artists = artistList
            self.isLoading = false
        }
    }
}
