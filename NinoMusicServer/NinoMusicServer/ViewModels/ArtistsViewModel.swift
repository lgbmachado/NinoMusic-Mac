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
        if let database = OpenDb() {
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
            var queryStatement1: OpaquePointer?
            var artistList = [Artist]()
            var albumList = [ArtistAlbum]()
            var seqArtist = 0
            var seqAlbum = 0
            var seqMusic = 0
            
            if sqlite3_prepare_v2(database, sqlArtist, -1, &queryStatement1, nil) == SQLITE_OK {
                while(sqlite3_step(queryStatement1) == SQLITE_ROW) {
                    seqArtist += 1
                    
                    let idArtist = String(cString: sqlite3_column_text(queryStatement1, 0))
                    let artist = String(cString: sqlite3_column_text(queryStatement1, 1))
                    let genre = String(cString: sqlite3_column_text(queryStatement1, 2))
                    
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
                    var queryStatement2: OpaquePointer?
                    var musicList = [ArtistMusic]()
                    
                    if sqlite3_prepare_v2(database, sqlAlbuns, -1, &queryStatement2, nil) == SQLITE_OK {
                        while(sqlite3_step(queryStatement2) == SQLITE_ROW) {
                            seqAlbum += 1
                            
                            let idAlbum = String(cString: sqlite3_column_text(queryStatement2, 0))
                            let album = String(cString: sqlite3_column_text(queryStatement2, 1))
                            let year = String(cString: sqlite3_column_text(queryStatement2, 2))
                            
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
                            
                            var queryStatement3: OpaquePointer?
                            if sqlite3_prepare_v2(database, sqlMusics, -1, &queryStatement3, nil) == SQLITE_OK {
                                while(sqlite3_step(queryStatement3) == SQLITE_ROW) {
                                    seqMusic += 1
                                    
                                    let idServer = Int(sqlite3_column_int(queryStatement3, 0))
                                    let track = Int(sqlite3_column_int(queryStatement3, 1))
                                    let musicTitle = String(cString: sqlite3_column_text(queryStatement3, 2))
                                    let duration = Int(sqlite3_column_int(queryStatement3, 3))
                                    let filePath = String(cString: sqlite3_column_text(queryStatement3, 4))
                                    
                                    musicList.append(ArtistMusic(seq: seqMusic,
                                                                 idServer: idServer,
                                                                 track: track,
                                                                 musicTitle: musicTitle,
                                                                 duration: duration,
                                                                 filePath: filePath))
                                }
                            }
                            albumList.append(ArtistAlbum(seq: seqAlbum,
                                                         album: album,
                                                         year: year,
                                                         musics: musicList))
                            musicList.removeAll()
                            sqlite3_finalize(queryStatement3)
                        }
                    }
                    artistList.append(Artist(seq: seqArtist,
                                             artist: artist,
                                             genre: genre,
                                             albuns: albumList))
                    albumList.removeAll()
                }
            }
            sqlite3_finalize(queryStatement1)
            self.artists = artistList
            CloseDb(database: database)
        }
    }
}
