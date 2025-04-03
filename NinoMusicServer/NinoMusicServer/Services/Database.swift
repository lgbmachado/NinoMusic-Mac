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
    
    private let colRowId = "RowId"
    
    //    private let databasePath = (Bundle.main.bundlePath as NSString).deletingLastPathComponent + "/MusicDatabase.db"
    private let databasePath = "/Users/nino/MusicDatabase.db"
    private var database: OpaquePointer?
    
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
            createTableDirectories()
            createTableMusics()
            createTableArtists()
            createTableAlbuns()
            createTableGenres()
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
        let idArtist = getRowId(table: self.tableArtists, column1: "Artist", value1: artist)
        let idAlbum = getRowId(table: self.tableAlbuns, column1: "Album", value1: album, column2: "Year", value2: String(year))
        let idGenre = getRowId(table: self.tableGenres, column1: "Genre", value1: genre)
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
           INNER JOIN \(self.tableArtists) ON \(self.tableArtists).\(self.colRowId) = \(self.tableMusics).IdArtist
           INNER JOIN \(self.tableAlbuns) ON \(self.tableAlbuns).\(self.colRowId) = \(self.tableMusics).IdAlbum
           INNER JOIN \(self.tableGenres) ON \(self.tableGenres).\(self.colRowId) = \(self.tableMusics).IdGenre
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
        let sql = """
        SELECT
           \(self.tableAlbuns).\(self.colAlbum),
           \(self.tableArtists).\(self.colArtist),
           \(self.tableAlbuns).\(self.colYear),
           \(self.tableGenres).\(self.colGenre),
           \(self.tableMusics).\(self.colRowId),
           \(self.tableMusics).\(self.colTrack),
           \(self.tableMusics).\(self.colTitle),
           \(self.tableMusics).\(self.colDuration),
           \(self.tableMusics).\(self.colFilePath)
        FROM
           \(self.tableMusics)
           INNER JOIN \(self.tableArtists) ON \(self.tableArtists).\(self.colRowId) = \(self.tableMusics).IdArtist
           INNER JOIN \(self.tableAlbuns) ON \(self.tableAlbuns).\(self.colRowId) = \(self.tableMusics).IdAlbum
           INNER JOIN \(self.tableGenres) ON \(self.tableGenres).\(self.colRowId) = \(self.tableMusics).IdGenre
        ORDER BY
           \(self.tableAlbuns).\(self.colAlbum),
           \(self.tableArtists).\(self.colArtist),
           \(self.tableAlbuns).\(self.colYear),
           \(self.tableMusics).\(self.colTrack)
        """
        var queryStatement: OpaquePointer?
        var albumList = [Album]()
        var musicList = [AlbumMusic]()
        var seqAlbum = 0
        var seqMusic = 0
        var lastAlbum = ""
        var lastArtist = ""
        var lastYear = ""
        var lastGenre = ""
        
        var isFirst = true
        
        if sqlite3_prepare_v2(self.database, sql, -1, &queryStatement, nil) == SQLITE_OK {
            while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                
                let album = String(cString: sqlite3_column_text(queryStatement, 0))
                let artist = String(cString: sqlite3_column_text(queryStatement, 1))
                let year = String(cString: sqlite3_column_text(queryStatement, 2))
                let genre = String(cString: sqlite3_column_text(queryStatement, 3))
                
                if !isFirst && (album != lastAlbum || artist != lastArtist || year != lastYear) {
                    seqAlbum += 1
                    albumList.append(Album(seq: seqAlbum,
                                           album: lastAlbum,
                                           artist: lastArtist,
                                           year: lastYear,
                                           genre: lastGenre,
                                           musics: musicList))
                    
                    seqMusic = 0
                    musicList.removeAll()
                }
                seqMusic += 1
                let idServer = Int(sqlite3_column_int(queryStatement, 4))
                let track = Int(sqlite3_column_int(queryStatement, 5))
                let musicTitle = String(cString: sqlite3_column_text(queryStatement, 6))
                let duration = Int(sqlite3_column_int(queryStatement, 7))
                let filePath = String(cString: sqlite3_column_text(queryStatement, 8))
                
                musicList.append(AlbumMusic(seq: seqMusic,
                                            idServer: idServer,
                                            track: track,
                                            musicTitle: musicTitle,
                                            duration: duration,
                                            filePath: filePath))
                isFirst = false
                lastAlbum = album
                lastArtist = artist
                lastYear = year
                lastGenre = genre
            }
        }
        sqlite3_finalize(queryStatement)
        return albumList
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
           INNER JOIN \(self.tableArtists) ON \(self.tableArtists).\(self.colRowId) = \(self.tableMusics).IdArtist
           INNER JOIN \(self.tableAlbuns) ON \(self.tableAlbuns).\(self.colRowId) = \(self.tableMusics).IdAlbum
           INNER JOIN \(self.tableGenres) ON \(self.tableGenres).\(self.colRowId) = \(self.tableMusics).IdGenre
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
        if column2 != "" && value2 != "" {
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
        let sqlDeleteRowsTableMusics = "DELETE FROM \(self.tableMusics);"
        var deleteRowsTableStatement: OpaquePointer?
        var result = false
        if sqlite3_prepare_v2(self.database, sqlDeleteRowsTableMusics, -1, &deleteRowsTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(deleteRowsTableStatement) == SQLITE_DONE {
                result = true
            }
        }
        sqlite3_finalize(deleteRowsTableStatement)
        return result
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
        let sqlDeleteRowsTableArtists = "DELETE FROM \(self.tableArtists);"
        var deleteRowsTableStatement: OpaquePointer?
        var result = false
        if sqlite3_prepare_v2(self.database, sqlDeleteRowsTableArtists, -1, &deleteRowsTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(deleteRowsTableStatement) == SQLITE_DONE {
                result = true
            }
        }
        sqlite3_finalize(deleteRowsTableStatement)
        return result
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
        let sqlDeleteRowsTableAlbuns = "DELETE FROM \(self.tableAlbuns);"
        var deleteRowsTableStatement: OpaquePointer?
        var result = false
        if sqlite3_prepare_v2(self.database, sqlDeleteRowsTableAlbuns, -1, &deleteRowsTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(deleteRowsTableStatement) == SQLITE_DONE {
                result = true
            }
        }
        sqlite3_finalize(deleteRowsTableStatement)
        return result
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
        let sqlDeleteRowsTableGenres = "DELETE FROM \(self.tableGenres);"
        var deleteRowsTableStatement: OpaquePointer?
        var result = false
        if sqlite3_prepare_v2(self.database, sqlDeleteRowsTableGenres, -1, &deleteRowsTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(deleteRowsTableStatement) == SQLITE_DONE {
                result = true
            }
        }
        sqlite3_finalize(deleteRowsTableStatement)
        return result
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
    
    func getDirectories() -> [Directory] {
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
        var dirList = [Directory]()
        var count = 0
        
        if sqlite3_prepare_v2(self.database, sql, -1, &queryStatement, nil) == SQLITE_OK {
            while(sqlite3_step(queryStatement) == SQLITE_ROW) {
                count += 1
                let dirName = String(cString: sqlite3_column_text(queryStatement, 1))
                let dirPath = String(cString: sqlite3_column_text(queryStatement, 2))
                
                dirList.append(Directory(name: dirName, path: dirPath))
            }
        }
        sqlite3_finalize(queryStatement)
        return dirList
    }
    
    private func deleteRowsTableDirectories() -> Bool {
        let sqlDeleteRowsTableDirs = "DELETE FROM \(self.tableDirectories);"
        var deleteRowsTableStatement: OpaquePointer?
        var result = false
        if sqlite3_prepare_v2(self.database, sqlDeleteRowsTableDirs, -1, &deleteRowsTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(deleteRowsTableStatement) == SQLITE_DONE {
                result = true
            }
        }
        sqlite3_finalize(deleteRowsTableStatement)
        return result
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

