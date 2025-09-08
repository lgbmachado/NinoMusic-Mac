//
//  ArtistsViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 03/09/25.
//

import Foundation
import SQLite3

class ArtistsViewModel: NSObject, ObservableObject {
    
    @Published var artists: [Artist] = []
    @Published var idMusicSelected: Music.ID = UUID()
    @Published var fileSelected: String = String()
    @Published var musicSelected: Music = Music.emptyMusic
    
    func reloadArtists() {
        var database: OpaquePointer?
        if sqlite3_open_v2(DBConstants.databasePath, &database, SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
            let sqlArtist = """
        SELECT DISTINCT
           \(DBConstants.TableMusic.colIdArtist),
           \(DBConstants.TableArtist.colArtist),
           \(DBConstants.TableGenre.colGenre)
        FROM
           \(DBConstants.TableMusic.tableName)
           INNER JOIN \(DBConstants.TableArtist.tableName) ON \(DBConstants.TableArtist.colRowId) = \(DBConstants.TableMusic.colIdArtist)
           INNER JOIN \(DBConstants.TableGenre.tableName) ON \(DBConstants.TableGenre.colRowId) = \(DBConstants.TableMusic.colIdGenre)
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
                    let idArtist = String(cString: sqlite3_column_text(queryStatement1, 0))
                    let artist = String(cString: sqlite3_column_text(queryStatement1, 1))
                    let genre = String(cString: sqlite3_column_text(queryStatement1, 2))
                    
                    let sqlAlbuns = """
        SELECT DISTINCT
           \(DBConstants.TableAlbum.colRowId),
           \(DBConstants.TableAlbum.colAlbum),
           \(DBConstants.TableAlbum.colYear)
        FROM
           \(DBConstants.TableMusic.tableName)
           INNER JOIN \(DBConstants.TableArtist.tableName) ON \(DBConstants.TableArtist.colRowId) = \(DBConstants.TableMusic.colIdArtist)
           INNER JOIN \(DBConstants.TableAlbum.tableName) ON \(DBConstants.TableAlbum.colRowId) = \(DBConstants.TableMusic.colIdAlbum)
        WHERE
           \(DBConstants.TableMusic.colIdArtist) = \(idArtist)
        ORDER BY
           \(DBConstants.TableAlbum.colYear),
           \(DBConstants.TableAlbum.colAlbum)
           
        """
                    var queryStatement2: OpaquePointer?
                    var musicList = [ArtistMusic]()
                    seqAlbum += 1
                    
                    if sqlite3_prepare_v2(database, sqlAlbuns, -1, &queryStatement2, nil) == SQLITE_OK {
                        while(sqlite3_step(queryStatement2) == SQLITE_ROW) {
                            
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
                            seqMusic = 0
                            albumList.append(ArtistAlbum(seq: seqAlbum,
                                                         album: album,
                                                         year: year,
                                                         musics: musicList))
                            musicList.removeAll()
                            sqlite3_finalize(queryStatement3)
                        }
                    }
                    seqArtist += 1
                    artistList.append(Artist(seq: seqArtist,
                                             artist: artist,
                                             genre: genre,
                                             albuns: albumList))
                    albumList.removeAll()
                }
            }
            sqlite3_finalize(queryStatement1)
            self.artists = artistList
            if sqlite3_close(database) != SQLITE_OK {
                print("Erro ao fechar banco de dados!")
            }
        } else {
            print("Erro ao abrir banco de dados!")
        }
    }
    
    func setIdSelection(selection: Music.ID) {
        for artist in self.artists {
                    for album in artist.albuns {
                        if let item = album.musics.first(where: { $0.id == selection }) {
                            self.musicSelected.id = item.id ?? UUID()
                            self.musicSelected.seq = item.seq
                            self.musicSelected.idServer = item.idServer
                            self.musicSelected.artist = artist.artist
                            self.musicSelected.album = album.album
                            self.musicSelected.year = album.year
                            self.musicSelected.track = item.track
                            self.musicSelected.musicTitle = item.musicTitle
                            self.musicSelected.genre = artist.genre
                            self.musicSelected.duration = item.duration
                            self.musicSelected.filePath = String((item.filePath as NSString).lastPathComponent).removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? ""
                            return
                        }
                    }
                }
    }
}
