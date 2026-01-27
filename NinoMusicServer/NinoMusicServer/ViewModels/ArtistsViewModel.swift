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
    @Published var idAlbumSelected: ArtistAlbum.ID? = nil
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
                    return
                }
            }
        }
    }
    
    func reloadArtists() {
        let sqlArtist = """
    SELECT DISTINCT
       \(DBConstants.TableMusic.colIdArtist),
       \(DBConstants.TableArtist.colArtist),
       \(DBConstants.TableGenre.colGenre)
    FROM
       \(DBConstants.TableMusic.tableName)
       INNER JOIN \(DBConstants.TableArtist.tableName) ON \(DBConstants.TableArtist.tableName).\(DBConstants.TableArtist.colRowId) = \(DBConstants.TableMusic.colIdArtist)
       INNER JOIN \(DBConstants.TableGenre.tableName) ON \(DBConstants.TableGenre.tableName).\(DBConstants.TableGenre.colRowId) = \(DBConstants.TableMusic.colIdGenre)
    ORDER BY
       \(DBConstants.TableArtist.colArtist),
       \(DBConstants.TableMusic.colTrack)
    """
        var artistList = [Artist]()
        var artistAlbumList = [ArtistAlbum]()
        var artistMusicList = [ArtistMusic]()
        var seqArtist = 0
        var seqAlbum = 0
        var seqMusic = 0
        do {
            if let rowsArtists = try self.helper?.executeQuery(query: sqlArtist) {
                for rowArtist in rowsArtists {
                    if let idArtist = rowArtist[DBConstants.TableMusic.colIdArtist] as? Int,
                       let artist = rowArtist[DBConstants.TableArtist.colArtist] as? String,
                       let genre = rowArtist[DBConstants.TableGenre.colGenre] as? String
                    {
                        seqArtist += 1
                        let sqlAlbuns = """
                               SELECT DISTINCT
                                  \(DBConstants.TableAlbum.tableName).\(DBConstants.TableAlbum.colRowId),
                                  \(DBConstants.TableAlbum.colAlbum),
                                  \(DBConstants.TableAlbum.colYear)
                               FROM
                                  \(DBConstants.TableMusic.tableName)
                                  INNER JOIN \(DBConstants.TableArtist.tableName) ON \(DBConstants.TableArtist.tableName).\(DBConstants.TableArtist.colRowId) = \(DBConstants.TableMusic.colIdArtist)
                                  INNER JOIN \(DBConstants.TableAlbum.tableName) ON \(DBConstants.TableAlbum.tableName).\(DBConstants.TableAlbum.colRowId) = \(DBConstants.TableMusic.colIdAlbum)
                               WHERE
                                  \(DBConstants.TableMusic.colIdArtist) = \(idArtist)
                               ORDER BY
                                  \(DBConstants.TableAlbum.colYear),
                                  \(DBConstants.TableAlbum.colAlbum)
                               
                               """
                        seqAlbum = 0
                        do {
                            if let rowsAlbuns = try self.helper?.executeQuery(query: sqlAlbuns) {
                                for rowAlbum in rowsAlbuns {
                                    if let idAlbum = rowAlbum[DBConstants.TableAlbum.colRowId] as? Int,
                                       let album = rowAlbum[DBConstants.TableAlbum.colAlbum] as? String,
                                       let year = rowAlbum[DBConstants.TableAlbum.colYear] as? String
                                    {
                                        let sqlMusics = """
                                                 SELECT
                                                    \(DBConstants.TableMusic.colRowId),
                                                    \(DBConstants.TableMusic.colTrack),
                                                    \(DBConstants.TableMusic.colTitle),
                                                    \(DBConstants.TableMusic.colDuration),
                                                    \(DBConstants.TableMusic.colFilePath)
                                                 FROM
                                                    \(DBConstants.TableMusic.tableName)
                                                 WHERE
                                                    \(DBConstants.TableMusic.colIdAlbum) = \(idAlbum) AND 
                                                    \(DBConstants.TableMusic.colIdArtist) = \(idArtist) 
                                                 ORDER BY
                                                    \(DBConstants.TableMusic.colTrack),
                                                    \(DBConstants.TableMusic.colTitle)
                                                 """
                                        do {
                                            if let rowsMusicsAlbum = try self.helper?.executeQuery(query: sqlMusics) {
                                                seqMusic = 0
                                                for rowMusicAlbum in rowsMusicsAlbum {
                                                    if let idServer = rowMusicAlbum[DBConstants.TableMusic.colRowId] as? Int,
                                                       let track = rowMusicAlbum[DBConstants.TableMusic.colTrack] as? Int,
                                                       let musicTitle = rowMusicAlbum[DBConstants.TableMusic.colTitle] as? String,
                                                       let duration = rowMusicAlbum[DBConstants.TableMusic.colDuration] as? Int,
                                                       let filePath = rowMusicAlbum[DBConstants.TableMusic.colFilePath] as? String
                                                    {
                                                        seqMusic += 1
                                                        artistMusicList.append(ArtistMusic(seq: seqMusic,
                                                                                           idServer: idServer,
                                                                                           track: track,
                                                                                           musicTitle: musicTitle,
                                                                                           duration: duration,
                                                                                           filePath: filePath))
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
        self.artists = artistList
    }
}
