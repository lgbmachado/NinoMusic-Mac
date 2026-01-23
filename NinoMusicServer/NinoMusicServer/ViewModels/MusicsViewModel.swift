//
//  MusicsViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 12/03/25.
//

import Foundation
import SQLite3

class MusicsViewModel: BaseViewModel {
        
    func reloadMusics() {
        if let database = OpenDb() {
            let sql = """
            SELECT
               \(DBConstants.TableMusic.tableName).\(DBConstants.TableMusic.colRowId),
               \(DBConstants.TableArtist.colArtist),
               \(DBConstants.TableMusic.colTitle),
               \(DBConstants.TableMusic.colTrack),
               \(DBConstants.TableAlbum.colAlbum),
               \(DBConstants.TableGenre.colGenre),
               \(DBConstants.TableMusic.colDuration),
               \(DBConstants.TableAlbum.colYear),
               \(DBConstants.TableMusic.colFilePath),
               \(DBConstants.TableMusic.colHasLyrics)
            FROM
               \(DBConstants.TableMusic.tableName)
               INNER JOIN \(DBConstants.TableArtist.tableName) ON \(DBConstants.TableArtist.tableName).\(DBConstants.TableArtist.colRowId) = \(DBConstants.TableMusic.colIdArtist)
               INNER JOIN \(DBConstants.TableAlbum.tableName) ON \(DBConstants.TableAlbum.tableName).\(DBConstants.TableAlbum.colRowId) = \(DBConstants.TableMusic.colIdAlbum)
               INNER JOIN \(DBConstants.TableGenre.tableName) ON \(DBConstants.TableGenre.tableName).\(DBConstants.TableGenre.colRowId) = \(DBConstants.TableMusic.colIdGenre)
            ORDER BY
               \(DBConstants.TableMusic.colTitle),
               \(DBConstants.TableArtist.colArtist)
            """
            var queryStatement: OpaquePointer?
            var musicList = [Music]()
            var seq = 0
            
            if sqlite3_prepare_v2(database, sql, -1, &queryStatement, nil) == SQLITE_OK {
                while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                    seq += 1
                    let idServer = Int(sqlite3_column_int(queryStatement, 0))
                    let artist = String(cString: sqlite3_column_text(queryStatement, 1))
                    let album = String(cString: sqlite3_column_text(queryStatement, 4))
                    let year = String(cString: sqlite3_column_text(queryStatement, 7))
                    let track = Int(sqlite3_column_int(queryStatement, 3))
                    let musicTitle = String(cString: sqlite3_column_text(queryStatement, 2))
                    let genre = String(cString: sqlite3_column_text(queryStatement, 5))
                    let duration = Int(sqlite3_column_int(queryStatement, 6))
                    let filePath = String(cString: sqlite3_column_text(queryStatement, 8))
                    let hasLyric = Int(sqlite3_column_int(queryStatement, 9)) == 1
                    
                    musicList.append(Music(seq: seq,
                                           idServer: idServer,
                                           artist: artist,
                                           album: album,
                                           year: year,
                                           track: track,
                                           musicTitle: musicTitle,
                                           genre: genre,
                                           duration: duration,
                                           filePath: filePath,
                                           hasLyric: hasLyric))
                }
            }
            sqlite3_finalize(queryStatement)
            self.musics = musicList
            CloseDb(database: database)
        }
    }
    
}
