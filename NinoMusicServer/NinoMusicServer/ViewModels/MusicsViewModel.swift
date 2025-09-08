//
//  MusicsViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 12/03/25.
//

import AVFAudio
import SQLite3

//enum NavigationKind {
//    case next
//    case previus
//}

class MusicsViewModel: NSObject, ObservableObject {
    
    @Published var musics: [Music] = []
    @Published var idMusicSelected: Music.ID = UUID()
    @Published var fileSelected: String = String()
    @Published var musicSelected: Music = Music.emptyMusic
    
    func reloadMusics() {
        var database: OpaquePointer?
        if sqlite3_open_v2(DBConstants.databasePath, &database, SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
            let sql = """
            SELECT
               \(DBConstants.TableMusic.colRowId),
               \(DBConstants.TableArtist.colArtist),
               \(DBConstants.TableMusic.colTitle),
               \(DBConstants.TableMusic.colTrack),
               \(DBConstants.TableAlbum.colAlbum),
               \(DBConstants.TableGenre.colGenre),
               \(DBConstants.TableMusic.colDuration),
               \(DBConstants.TableAlbum.colYear),
               \(DBConstants.TableMusic.colFilePath)
            FROM
               \(DBConstants.TableMusic.tableName)
               INNER JOIN \(DBConstants.TableArtist.tableName) ON \(DBConstants.TableArtist.colRowId) = \(DBConstants.TableMusic.colIdArtist)
               INNER JOIN \(DBConstants.TableAlbum.tableName) ON \(DBConstants.TableAlbum.colRowId) = \(DBConstants.TableMusic.colIdAlbum)
               INNER JOIN \(DBConstants.TableGenre.tableName) ON \(DBConstants.TableGenre.colRowId) = \(DBConstants.TableMusic.colIdGenre)
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
                    
                    musicList.append(Music(seq: seq,
                                           idServer: idServer,
                                           artist: artist,
                                           album: album,
                                           year: year,
                                           track: track,
                                           musicTitle: musicTitle,
                                           genre: genre,
                                           duration: duration,
                                           filePath: filePath))
                }
            }
            sqlite3_finalize(queryStatement)
            self.musics = musicList
            if sqlite3_close(database) != SQLITE_OK {
                print("Erro ao fechar banco de dados!")
            }
        } else {
            print("Erro ao abrir banco de dados!")
        }
    }
    
    func setIdSelection(selection: Music.ID) {
        self.idMusicSelected = selection
        if let item = self.musics.first(where: { $0.id == self.idMusicSelected }) {
            self.idMusicSelected = item.id
            self.musicSelected = item
            self.fileSelected = String((item.filePath as NSString).lastPathComponent).removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? ""
        } else {
            self.musicSelected = Music.emptyMusic
        }
    }
    
}
