//
//  AlbunsViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 01/04/25.
//

import Foundation
import SQLite3

class AlbunsViewModel: BaseViewModel {
    @Published var filePathCover: String = String()
    
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
    
    func reloadAlbuns() {
        if let database = OpenDb() {
            let sqlAlbuns = """
            SELECT DISTINCT
               \(DBConstants.TableMusic.colIdAlbum),
               \(DBConstants.TableAlbum.colAlbum),
               \(DBConstants.TableArtist.colArtist),
               \(DBConstants.TableAlbum.colYear),
               \(DBConstants.TableGenre.colGenre)
            FROM
               \(DBConstants.TableMusic.tableName)
               INNER JOIN \(DBConstants.TableArtist.tableName) ON \(DBConstants.TableArtist.tableName).\(DBConstants.TableArtist.colRowId) = \(DBConstants.TableMusic.colIdArtist)
               INNER JOIN \(DBConstants.TableAlbum.tableName) ON \(DBConstants.TableAlbum.tableName).\(DBConstants.TableAlbum.colRowId) = \(DBConstants.TableMusic.colIdAlbum)
               INNER JOIN \(DBConstants.TableGenre.tableName) ON \(DBConstants.TableGenre.tableName).\(DBConstants.TableGenre.colRowId) = \(DBConstants.TableMusic.colIdGenre)
            ORDER BY
               \(DBConstants.TableAlbum.colAlbum),
               \(DBConstants.TableArtist.colArtist),
               \(DBConstants.TableAlbum.colYear),
               \(DBConstants.TableMusic.colTrack)
            """
            var queryStatement1: OpaquePointer?
            var albumList = [Album]()
            var musicList = [AlbumMusic]()
            var seqAlbum = 0
            
            if sqlite3_prepare_v2(database, sqlAlbuns, -1, &queryStatement1, nil) == SQLITE_OK {
                while(sqlite3_step(queryStatement1) == SQLITE_ROW) {
                    
                    let idAlbum = String(cString: sqlite3_column_text(queryStatement1, 0))
                    let album = String(cString: sqlite3_column_text(queryStatement1, 1))
                    let artist = String(cString: sqlite3_column_text(queryStatement1, 2))
                    let year = String(cString: sqlite3_column_text(queryStatement1, 3))
                    let genre = String(cString: sqlite3_column_text(queryStatement1, 4))
                    
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
                       \(DBConstants.TableMusic.colIdAlbum) = \(idAlbum) 
                    ORDER BY
                       \(DBConstants.TableMusic.colTrack),
                       \(DBConstants.TableMusic.colTitle)
                    """
                    
                    var queryStatement2: OpaquePointer?
                    var seqMusic = 0
                    if sqlite3_prepare_v2(database, sqlMusics, -1, &queryStatement2, nil) == SQLITE_OK {
                        while(sqlite3_step(queryStatement2) == SQLITE_ROW) {
                            seqMusic += 1
                            
                            let idServer = Int(sqlite3_column_int(queryStatement2, 0))
                            let track = Int(sqlite3_column_int(queryStatement2, 1))
                            let musicTitle = String(cString: sqlite3_column_text(queryStatement2, 2))
                            let duration = Int(sqlite3_column_int(queryStatement2, 3))
                            let filePath = String(cString: sqlite3_column_text(queryStatement2, 4))
                            
                            musicList.append(AlbumMusic(seq: seqMusic,
                                                        idServer: idServer,
                                                        track: track,
                                                        musicTitle: musicTitle,
                                                        duration: duration,
                                                        filePath: filePath))
                        }
                    }
                    seqAlbum += 1
                    albumList.append(Album(seq: seqAlbum,
                                           album: album,
                                           artist: artist,
                                           year: year,
                                           genre: genre,
                                           musics: musicList))
                    
                    seqMusic = 0
                    musicList.removeAll()
                    sqlite3_finalize(queryStatement2)
                }
            }
            sqlite3_finalize(queryStatement1)
            self.albuns = albumList
            CloseDb(database: database)
        }
    }
}

