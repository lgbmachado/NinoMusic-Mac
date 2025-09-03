//
//  Database.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 27/08/24.
//

import Foundation
import ID3TagEditor
import SQLite3
import SwiftUI

class Database {
    
    //    private let databasePath = (Bundle.main.bundlePath as NSString).deletingLastPathComponent + "/MusicDatabase.db"
    private let databasePath = "/Users/nino/MusicDatabase.db"
    private var database: OpaquePointer?
    
    private let colRowId = "RowId"
    
    private let tableDirectories = "Directories"
    private let colDirName = "Name"
    private let colDirPath = "DirPath"
    
    private let tableMusics = "Musics"
    private let colFilePath = "FilePath"
    private let colIdArtist = "IdArtist"
    private let colDuration = "Duration"
    private let colTrack = "Track"
    private let colIdAlbum = "IdAlbum"
    private let colTitle = "Title"
    private let colIdGenre = "IdGenre"
    
    private let tableArtists = "Artists"
    private let colArtist = "Artist"
    
    private let tableAlbuns = "Albuns"
    private let colAlbum = "Album"
    private let colYear = "Year"
    
    private let tableGenres = "Genres"
    private let colGenre = "Genre"
    
    init () {
        print("Path banco de dados: \(self.databasePath)")
        
        if sqlite3_open_v2(self.databasePath, &database, SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
            CreateTables()
        } else {
        }
    }
    
    
    func cleanMusicsTables() {
        if !deleteRowsTableAlbuns() {
            
        }
        if !deleteRowsTableGenres() {
            
        }
        if !deleteRowsTableArtists() {
            
        }
        if !deleteRowsTableMusics() {
            
        }
    }
    
    func AddMusic(filePath: String, musicTitle: String, artist: String, album: String, year: Int, track: Int, duration: Int, genre: String) -> Bool{
        let idArtist = getRowId(table: self.tableArtists, column1: self.colArtist, value1: artist)
        let idAlbum = getRowId(table: self.tableAlbuns, column1: self.colAlbum, value1: album, column2: self.colYear, value2: String(year))
        let idGenre = getRowId(table: self.tableGenres, column1: self.colGenre, value1: genre)
        var result = false
        
        var queryStatement: OpaquePointer?
        let sql = "INSERT INTO \(self.tableMusics) (\(self.colFilePath), \(self.colIdArtist), \(self.colTrack), \(self.colDuration), \(self.colIdAlbum), \(self.colTitle), \(self.colIdGenre)) VALUES (\"\(filePath)\", \(idArtist), \(track), \(duration), \(idAlbum), \"\(musicTitle.replacingOccurrences(of: "\"", with: "'"))\", \(idGenre) );"
        if sqlite3_prepare_v2(self.database, sql, -1, &queryStatement, nil) == SQLITE_OK {
            if sqlite3_step(queryStatement) == SQLITE_DONE {
                result = true
            }
        }
        sqlite3_finalize(queryStatement)
        return result
    }
    
    func getMusics() -> [Music] {
        let sql = """
        SELECT
           \(self.tableMusics).\(self.colRowId),
           \(self.tableArtists).\(self.colArtist),
           \(self.tableMusics).\(self.colTitle),
           \(self.tableMusics).\(self.colTrack),
           \(self.tableAlbuns).\(self.colAlbum),
           \(self.tableGenres).\(self.colGenre),
           \(self.tableMusics).\(self.colDuration),
           \(self.tableAlbuns).\(self.colYear),
           \(self.tableMusics).\(self.colFilePath)
        FROM
           \(self.tableMusics)
           INNER JOIN \(self.tableArtists) ON \(self.tableArtists).\(self.colRowId) = \(self.tableMusics).\(self.colIdArtist)
           INNER JOIN \(self.tableAlbuns) ON \(self.tableAlbuns).\(self.colRowId) = \(self.tableMusics).\(self.colIdAlbum)
           INNER JOIN \(self.tableGenres) ON \(self.tableGenres).\(self.colRowId) = \(self.tableMusics).\(self.colIdGenre)
        ORDER BY
           \(self.tableMusics).\(self.colTitle),
           \(self.tableArtists).\(self.colArtist)
        """
        var queryStatement: OpaquePointer?
        var musicList = [Music]()
        var seq = 0
        
        if sqlite3_prepare_v2(self.database, sql, -1, &queryStatement, nil) == SQLITE_OK {
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
        return musicList
    }
    
    func getAlbuns() -> [Album] {
        let sqlAlbuns = """
        SELECT DISTINCT
           \(self.tableMusics).\(self.colIdAlbum),
           \(self.tableAlbuns).\(self.colAlbum),
           \(self.tableArtists).\(self.colArtist),
           \(self.tableAlbuns).\(self.colYear),
           \(self.tableGenres).\(self.colGenre)
        FROM
           \(self.tableMusics)
           INNER JOIN \(self.tableArtists) ON \(self.tableArtists).\(self.colRowId) = \(self.tableMusics).\(self.colIdArtist)
           INNER JOIN \(self.tableAlbuns) ON \(self.tableAlbuns).\(self.colRowId) = \(self.tableMusics).\(self.colIdAlbum)
           INNER JOIN \(self.tableGenres) ON \(self.tableGenres).\(self.colRowId) = \(self.tableMusics).\(self.colIdGenre)
        ORDER BY
           \(self.tableAlbuns).\(self.colAlbum),
           \(self.tableArtists).\(self.colArtist),
           \(self.tableAlbuns).\(self.colYear),
           \(self.tableMusics).\(self.colTrack)
        """
        var queryStatement1: OpaquePointer?
        var albumList = [Album]()
        var musicList = [AlbumMusic]()
        var seqAlbum = 0
        
        if sqlite3_prepare_v2(self.database, sqlAlbuns, -1, &queryStatement1, nil) == SQLITE_OK {
            while(sqlite3_step(queryStatement1) == SQLITE_ROW) {
                
                let idAlbum = String(cString: sqlite3_column_text(queryStatement1, 0))
                let album = String(cString: sqlite3_column_text(queryStatement1, 1))
                let artist = String(cString: sqlite3_column_text(queryStatement1, 2))
                let year = String(cString: sqlite3_column_text(queryStatement1, 3))
                let genre = String(cString: sqlite3_column_text(queryStatement1, 4))
                
                let sqlMusics = """
                SELECT
                   \(self.tableMusics).\(self.colRowId),
                   \(self.tableMusics).\(self.colTrack),
                   \(self.tableMusics).\(self.colTitle),
                   \(self.tableMusics).\(self.colDuration),
                   \(self.tableMusics).\(self.colFilePath)
                FROM
                   \(self.tableMusics)
                WHERE
                   \(self.tableMusics).\(self.colIdAlbum) = \(idAlbum) 
                ORDER BY
                   \(self.tableMusics).\(self.colTrack),
                   \(self.tableMusics).\(self.colTitle)
                """
                
                var queryStatement2: OpaquePointer?
                var seqMusic = 0
                if sqlite3_prepare_v2(self.database, sqlMusics, -1, &queryStatement2, nil) == SQLITE_OK {
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
        return albumList
    }
    
    func getArtists() -> [Artist] {
        let sqlArtist = """
        SELECT DISTINCT
           \(self.tableMusics).\(self.colIdArtist),
           \(self.tableArtists).\(self.colArtist),
           \(self.tableGenres).\(self.colGenre)
        FROM
           \(self.tableMusics)
           INNER JOIN \(self.tableArtists) ON \(self.tableArtists).\(self.colRowId) = \(self.tableMusics).\(self.colIdArtist)
           INNER JOIN \(self.tableGenres) ON \(self.tableGenres).\(self.colRowId) = \(self.tableMusics).\(self.colIdGenre)
        ORDER BY
           \(self.tableArtists).\(self.colArtist),
           \(self.tableMusics).\(self.colTrack)
        """
        var queryStatement1: OpaquePointer?
        var artistList = [Artist]()
        var albumList = [ArtistAlbum]()
        var seqArtist = 0
        var seqAlbum = 0
        var seqMusic = 0
        
        
        if sqlite3_prepare_v2(self.database, sqlArtist, -1, &queryStatement1, nil) == SQLITE_OK {
            while(sqlite3_step(queryStatement1) == SQLITE_ROW) {
                let idArtist = String(cString: sqlite3_column_text(queryStatement1, 0))
                let artist = String(cString: sqlite3_column_text(queryStatement1, 1))
                let genre = String(cString: sqlite3_column_text(queryStatement1, 2))
                
                let sqlAlbuns = """
        SELECT DISTINCT
           \(self.tableAlbuns).\(self.colRowId),
           \(self.tableAlbuns).\(self.colAlbum),
           \(self.tableAlbuns).\(self.colYear)
        FROM
           \(self.tableAlbuns)
           INNER JOIN \(self.tableArtists) ON \(self.tableArtists).\(self.colRowId) = \(self.tableMusics).\(self.colIdArtist)
           INNER JOIN \(self.tableMusics) ON \(self.tableAlbuns).\(self.colRowId) = \(self.tableMusics).\(self.colIdAlbum)
        WHERE
           \(self.tableMusics).\(self.colIdArtist) = \(idArtist) 
        ORDER BY
           \(self.tableAlbuns).\(self.colYear),
           \(self.tableAlbuns).\(self.colAlbum)
           
        """
                var queryStatement2: OpaquePointer?
                var musicList = [ArtistMusic]()
                seqAlbum += 1
                
                if sqlite3_prepare_v2(self.database, sqlAlbuns, -1, &queryStatement2, nil) == SQLITE_OK {
                    while(sqlite3_step(queryStatement2) == SQLITE_ROW) {
                        
                        let idAlbum = String(cString: sqlite3_column_text(queryStatement2, 0))
                        let album = String(cString: sqlite3_column_text(queryStatement2, 1))
                        let year = String(cString: sqlite3_column_text(queryStatement2, 2))
                        
                        let sqlMusics = """
                SELECT
                   \(self.tableMusics).\(self.colRowId),
                   \(self.tableMusics).\(self.colTrack),
                   \(self.tableMusics).\(self.colTitle),
                   \(self.tableMusics).\(self.colDuration),
                   \(self.tableMusics).\(self.colFilePath)
                FROM
                   \(self.tableMusics)
                WHERE
                   \(self.tableMusics).\(self.colIdAlbum) = \(idAlbum) 
                ORDER BY
                   \(self.tableMusics).\(self.colTrack),
                   \(self.tableMusics).\(self.colTitle)
                """
                        
                        var queryStatement3: OpaquePointer?
                        if sqlite3_prepare_v2(self.database, sqlMusics, -1, &queryStatement3, nil) == SQLITE_OK {
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
        return artistList
    }
    
    func listMusicsRemote(completion: @escaping ([Music]?) -> ()) {
        let sql = """
        SELECT
           \(self.tableMusics).\(self.colRowId),
           \(self.tableArtists).\(self.colArtist),
           \(self.tableMusics).\(self.colTitle),
           \(self.tableMusics).\(self.colTrack),
           \(self.tableMusics).\(self.colDuration),
           \(self.tableAlbuns).\(self.colAlbum),
           \(self.tableGenres).\(self.colGenre),
           \(self.tableAlbuns).\(self.colYear)
        FROM
           \(self.tableMusics)
           INNER JOIN \(self.tableArtists) ON \(self.tableArtists).\(self.colRowId) = \(self.tableMusics).\(self.colIdArtist)
           INNER JOIN \(self.tableAlbuns) ON \(self.tableAlbuns).\(self.colRowId) = \(self.tableMusics).\(self.colIdAlbum)
           INNER JOIN \(self.tableGenres) ON \(self.tableGenres).\(self.colRowId) = \(self.tableMusics).\(self.colIdGenre)
        ORDER BY
           \(self.tableMusics).\(self.colTitle),
           \(self.tableArtists).\(self.colArtist)
        """
        var queryStatement: OpaquePointer?
        var musicListRemote = [Music]()
        var seq = 0
        
        if sqlite3_prepare_v2(self.database, sql, -1, &queryStatement, nil) == SQLITE_OK {
            while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                seq += 1
                let idServer = Int(sqlite3_column_int(queryStatement, 0))
                let artist = String(cString: sqlite3_column_text(queryStatement, 1))
                let album = String(cString: sqlite3_column_text(queryStatement, 5))
                let year = String(cString: sqlite3_column_text(queryStatement, 7))
                let track = Int(sqlite3_column_int(queryStatement, 3))
                let musicTitle = String(cString: sqlite3_column_text(queryStatement, 2))
                let genre = String(cString: sqlite3_column_text(queryStatement, 6))
                let duration = Int(sqlite3_column_int(queryStatement, 4))
                
                musicListRemote.append(Music(seq: seq,
                                             idServer: idServer,
                                             artist: artist,
                                             album: album,
                                             year: year,
                                             track: track,
                                             musicTitle: musicTitle,
                                             genre: genre,
                                             duration: duration,
                                             filePath: ""))
            }
        }
        sqlite3_finalize(queryStatement)
        completion(musicListRemote)
    }
    
    func musicExists(filePath: String) -> Bool {
        let sql = """
        SELECT
           *
        FROM
           \(self.tableMusics)
        WHERE
           \(self.colFilePath) = \"\(filePath)\"
        """
        var queryStatement: OpaquePointer?
        var count = 0
        if sqlite3_prepare_v2(self.database, sql, -1, &queryStatement, nil) == SQLITE_OK {
            while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                count += 1
            }
        }
        sqlite3_finalize(queryStatement)
        return count > 0
    }
    
    func getMusicById(id: Int, completion: @escaping (String?) -> ()) {
        let sql = """
        SELECT
           \(self.tableMusics).\(self.colFilePath)
        FROM
           \(self.tableMusics)
        WHERE
           \(self.colRowId) = \(id)
        """
        var queryStatement: OpaquePointer?
        var result = ""
        
        if sqlite3_prepare_v2(self.database, sql, -1, &queryStatement, nil) == SQLITE_OK {
            while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                result = String(cString: sqlite3_column_text(queryStatement, 0))
            }
        }
        sqlite3_finalize(queryStatement)
        completion(result)
    }
    
    func closeDatabase() {
        if sqlite3_close(self.database) != SQLITE_OK {
            print("error closing database")
        }
    }
    
    func getRowId(table: String, column1: String, value1: String, column2: String = "", value2: String = "") -> Int {
        var queryStatement: OpaquePointer?
        var sql = ""
        if !column2.isEmpty && !value2.isEmpty {
            sql = "SELECT \(self.colRowId) FROM \(table) WHERE \(column1) = \"\(value1.replacingOccurrences(of: "\"", with: "'"))\" AND \(column2) = \"\(value2.replacingOccurrences(of: "\"", with: "'"))\";"
        } else {
            sql = "SELECT \(self.colRowId) FROM \(table) WHERE \(column1) = \"\(value1.replacingOccurrences(of: "\"", with: "'"))\""
        }
        var result = 0
        if sqlite3_prepare_v2(self.database, sql, -1, &queryStatement, nil) == SQLITE_OK {
            if sqlite3_step(queryStatement) == SQLITE_ROW {
                result = Int(sqlite3_column_int(queryStatement, 0))
            } else {
                if column2 != "" && value2 != "" {
                    sql = "INSERT INTO \(table) (\(column1), \(column2)) VALUES (\"\(value1.replacingOccurrences(of: "\"", with: "'"))\", \"\(value2.replacingOccurrences(of: "\"", with: "'"))\");"
                } else {
                    sql = "INSERT INTO \(table) (\(column1)) VALUES (\"\(value1.replacingOccurrences(of: "\"", with: "'"))\");"
                }
                if sqlite3_exec(self.database, sql, nil, nil, nil) == SQLITE_OK {
                    result = Int(sqlite3_last_insert_rowid(self.database))
                }
            }
        }
        sqlite3_finalize(queryStatement)
        return result
    }
    
    private func CreateTables() {
        createTableDirectories()
        createTableMusics()
        createTableArtists()
        createTableAlbuns()
        createTableGenres()
    }
    
    private func createTable(sql: String) -> Bool {
        var createTableStatement: OpaquePointer?
        var result = false
        if sqlite3_prepare_v2(self.database, sql, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                result = true
            }
        }
        sqlite3_finalize(createTableStatement)
        return result
    }
    
    private func deleteRows(table: String) -> Bool {
        let sqlDeleteRowsTable = "DELETE FROM \(table);"
        var deleteRowsTableStatement: OpaquePointer?
        var result = false
        if sqlite3_prepare_v2(self.database, sqlDeleteRowsTable, -1, &deleteRowsTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(deleteRowsTableStatement) == SQLITE_DONE {
                result = true
            }
        }
        sqlite3_finalize(deleteRowsTableStatement)
        return result
    }
    
    private func createTableMusics() {
        let sqlCreateTableMusics = """
        CREATE TABLE IF NOT EXISTS \(self.tableMusics) (
        \(self.colFilePath) CHAR(255) PRIMARY KEY NOT NULL,
        \(self.colIdArtist) INT,
        \(self.colIdAlbum) INT,
        \(self.colDuration) INT,
        \(self.colTrack) INT,
        \(self.colTitle) CHAR(255),
        \(self.colIdGenre) INT);
        """
        if createTable(sql: sqlCreateTableMusics) {
            
        }
    }
    
    private func deleteRowsTableMusics() -> Bool {
        return deleteRows(table: self.tableMusics)
    }
    
    private func createTableArtists() {
        let sqlCreateTableArtists = """
        CREATE TABLE IF NOT EXISTS \(self.tableArtists) (
        \(self.colArtist) CHAR(255) PRIMARY KEY NOT NULL);
        """
        if createTable(sql: sqlCreateTableArtists) {
            
        }
    }
    
    private func deleteRowsTableArtists() -> Bool {
        return deleteRows(table: self.tableArtists)
    }
    
    private func createTableAlbuns() {
        let sqlCreateTableAlbuns = """
        CREATE TABLE IF NOT EXISTS \(self.tableAlbuns) (
        \(self.colAlbum) CHAR(255) PRIMARY KEY NOT NULL,
        \(self.colYear) CHAR(4));
        """
        if createTable(sql: sqlCreateTableAlbuns) {
            
        }
    }
    
    private func deleteRowsTableAlbuns() -> Bool {
        return deleteRows(table: self.tableAlbuns)
    }
    
    private func createTableGenres() {
        let sqlCreateTableGenres = """
        CREATE TABLE IF NOT EXISTS \(self.tableGenres) (
        \(self.colGenre) CHAR(255) PRIMARY KEY NOT NULL);
        """
        if createTable(sql: sqlCreateTableGenres) {
            
        }
    }
    
    private func deleteRowsTableGenres() -> Bool {
        return deleteRows(table: self.tableGenres)
    }
    
    private func createTableDirectories() {
        let sqlCreateTableDir = """
        CREATE TABLE IF NOT EXISTS \(self.tableDirectories) (
        \(self.colDirPath) CHAR(255) PRIMARY KEY NOT NULL,
        \(self.colDirName) CHAR(75));
        """
        if createTable(sql: sqlCreateTableDir) {
            
        }
    }
    
    func getDirectories() -> [MusicDirectory] {
        let sql = """
        SELECT
           \(self.tableDirectories).\(self.colRowId),
           \(self.tableDirectories).\(self.colDirName),
           \(self.tableDirectories).\(self.colDirPath)
        FROM
           \(self.tableDirectories)
        ORDER BY
           \(self.tableDirectories).\(self.colDirName)
        """
        var queryStatement: OpaquePointer?
        var dirList = [MusicDirectory]()
        var count = 0
        
        if sqlite3_prepare_v2(self.database, sql, -1, &queryStatement, nil) == SQLITE_OK {
            while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                count += 1
                let dirName = String(cString: sqlite3_column_text(queryStatement, 1))
                let dirPath = String(cString: sqlite3_column_text(queryStatement, 2))
                
                dirList.append(MusicDirectory(name: dirName, path: dirPath))
            }
        }
        sqlite3_finalize(queryStatement)
        return dirList
    }
    
    private func deleteRowsTableDirectories() -> Bool {
        return deleteRows(table: self.tableDirectories)
    }
    
    private func updateRowsTableDirectories() -> Bool {
        var result = true
        
        var queryStatement: OpaquePointer?
        let sql1 = """
        SELECT
           \(self.tableDirectories).\(self.colRowId)
        FROM
           \(self.tableDirectories)
        """
        var rowIdList = [String]()
        if sqlite3_prepare_v2(self.database, sql1, -1, &queryStatement, nil) == SQLITE_OK {
            while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                rowIdList.append(String(cString: sqlite3_column_text(queryStatement, 0)))
            }
        }
        sqlite3_finalize(queryStatement)
        
        if rowIdList.count > 0 {
            var count = 1
            for rowId in rowIdList {
                let sql2 = "UPDATE \(tableDirectories) SET \(colDirName) = \"Dir \(String(format: "%02d", count))\" WHERE \(self.colRowId) = \(rowId);"
                if sqlite3_prepare_v2(self.database, sql2, -1, &queryStatement, nil) != SQLITE_OK {
                    result = false
                } else {
                    if sqlite3_step(queryStatement) != SQLITE_DONE {
                        result = false
                    }
                }
                sqlite3_finalize(queryStatement)
                count += 1
            }
        }
        
        return result
    }
    
    func addDirectory(dirPath: String) -> Bool{
        var result = false
        
        var queryStatement: OpaquePointer?
        let sql = "INSERT INTO \(self.tableDirectories) (\(self.colDirPath)) VALUES (\"\(dirPath)\");"
        if sqlite3_prepare_v2(self.database, sql, -1, &queryStatement, nil) == SQLITE_OK {
            if sqlite3_step(queryStatement) == SQLITE_DONE {
                result = true
            }
        }
        sqlite3_finalize(queryStatement)
        
        if updateRowsTableDirectories() {
            result = true
        }
        
        return result
    }
    
    func deleteDirectory(dirName: String) -> Bool {
        var result = true
        
        var queryStatement: OpaquePointer?
        let sqlDeleteRowsTableDirs = "DELETE FROM \(self.tableDirectories) WHERE \(self.colDirName) = \"\(dirName)\";"
        var deleteRowsTableStatement: OpaquePointer?
        if sqlite3_prepare_v2(self.database, sqlDeleteRowsTableDirs, -1, &deleteRowsTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(deleteRowsTableStatement) == SQLITE_DONE {
                result = true
            }
        }
        sqlite3_finalize(queryStatement)
        
        if updateRowsTableDirectories() {
            result = true
        }
        return result
    }
}

