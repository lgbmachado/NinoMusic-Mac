//
//  LibraryViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 14/03/25.
//

import AVFoundation
import Foundation
import ID3TagEditor
import SQLite3

class LibraryViewModel: ObservableObject, MusicFilesDelegate {
    
    @Published var musics: [Music] = []
    @Published var totalMusics: Int = 0
    @Published var totalTime: TimeInterval = 0
    @Published var isLoading: Bool = false
    
    @Published var directories = [MusicDirectory]()
    
    private var musicFiles = MusicFiles()
    
    init() {
        self.musicFiles.delegate = self
        self.directories = self.musicFiles.directories
        self.musics = self.musicFiles.musics
    }
     
    func addDirectory(dirPath: String) async {
        self.isLoading = true
        await self.musicFiles.addDirectory(dirPath: dirPath.removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? "")
        self.directories = self.musicFiles.directories
        self.musics = self.musicFiles.musics
        self.isLoading = false
    }
    
    func deleteDirectory(selection: UUID) async {
        self.isLoading = true
        if let dir = musicFiles.directories.first(where: { $0.id == selection }) {
            await self.musicFiles.deleteDirectory(dirName: dir.name)
            self.directories = self.musicFiles.directories
            self.musics = self.musicFiles.musics
            self.totalTime = self.musicFiles.totalTime
            self.totalMusics = self.musicFiles.musics.count
            self.isLoading = false
        } else {
            self.isLoading = false
        }

    }
}

extension LibraryViewModel {
    
    func musicLoading(musicsLoaded: Int, totalTime: TimeInterval) {
        self.totalMusics = musicsLoaded
        self.totalTime = totalTime
    }
}

protocol MusicFilesDelegate {
    func musicLoading(musicsLoaded: Int, totalTime: TimeInterval)
}

class MusicFiles {
    
    private var count = 0
    private var database: OpaquePointer?
    
    var delegate: MusicFilesDelegate?
    var directories = [MusicDirectory]()
    var musics = [Music]()
    var albuns = [Album]()
    var artists = [Artist]()
    var totalTime: TimeInterval = 0
    
    init() {
        self.directories = getDirectories()
        
        print("Path banco de dados (Library): \(DBConstants.databasePath)")
        if sqlite3_open_v2(DBConstants.databasePath, &database, SQLITE_OPEN_CREATE|SQLITE_OPEN_READWRITE|SQLITE_OPEN_FULLMUTEX, nil) == SQLITE_OK {
            CreateTables()
        } else {
        }
    }
    
    func addDirectory(dirPath: String) async {
        if addDirectory(dirPath: dirPath) {
            self.directories = getDirectories()
            await updateMusicsDatabase { _ in
                self.saveServerInfo()
            }
        }
    }
    
    func deleteDirectory(dirName: String) async {
        if deleteDirectory(dirName: dirName) {
            self.directories = self.getDirectories()
            await updateMusicsDatabase { _ in
//                self.musics = self.musicDb.getMusics()
//                self.albuns = self.musicDb.getAlbuns()
                self.saveServerInfo()
            }
        }
    }
    
    private func updateMusicsDatabase(completion: @escaping (Int?) -> ()) async {
        cleanMusicsTables()
        for dir in self.directories {
            let url = URL(fileURLWithPath: dir.path)
            var directories = [URL]()
            directories.append(url)
            if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
                for case let dirURL as URL in enumerator {
                    do {
                        let dirAttributes = try dirURL.resourceValues(forKeys:[.isDirectoryKey])
                        if dirAttributes.isDirectory! {
                            directories.append(dirURL)
                        }
                    } catch { print(error, dirURL) }
                }
                let id3TagEditor: ID3TagEditor = ID3TagEditor()
                
                for urlDir in directories {
                    if let enumFiles = FileManager.default.enumerator(at: urlDir, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
                        for case let fileURL as URL in enumFiles {
                            if fileURL.pathExtension.uppercased() == "MP3" {
                                if !musicExists(filePath: fileURL.absoluteString) {
                                    do {
                                        let id3Tag = try id3TagEditor.read(from: fileURL.path)
                                        
                                        let artist = ((id3Tag?.frames[.artist] as? ID3FrameWithStringContent)?.content ?? String()) as String
                                        let album = ((id3Tag?.frames[ .album] as? ID3FrameWithStringContent)?.content ?? String()) as String
                                        let year = ((id3Tag?.frames[.recordingYear] as? ID3FrameWithIntegerContent)?.value ?? Int()) as Int
                                        let track = ((id3Tag?.frames[.trackPosition] as? ID3FramePartOfTotal)?.part ?? Int()) as Int
                                        let duration = await getDuration(url: fileURL)
                                        let musicTitle = ((id3Tag?.frames[.title] as? ID3FrameWithStringContent)?.content ?? String()) as String
                                        let genre = ((id3Tag?.frames[.genre] as? ID3FrameGenre)?.description ?? String()) as String
                                        let filePath = fileURL.absoluteString
                                        
                                        if AddMusic(filePath: filePath,
                                                                 musicTitle: musicTitle,
                                                                 artist: artist,
                                                                 album: album,
                                                                 year: year,
                                                                 track: track,
                                                                 duration: duration,
                                                                 genre: genre) {
                                            
                                            if count % 49 == 0 {
                                                delegate?.musicLoading(musicsLoaded: count, totalTime: totalTime)
                                            }
                                            count += 1
                                            totalTime += Double(duration)
                                        }
                                    }
                                    catch {
                                        print(error)
                                    }
                                }
                            }
                        }
                    }
                }
                completion(count)
            }
        }
    }

    private func getDuration(url: URL) async -> Int {
        do {
            let audioAsset = AVURLAsset.init(url: url, options: nil)
            let duration = try await audioAsset.load(.duration)
            return ("\(CMTimeGetSeconds(duration))" as NSString).integerValue
        } catch {
            return 0
        }
    }
    
    private func saveServerInfo() {
        if let deviceName = Host.current().localizedName {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMddHHmmss"
            let lastUpdate = dateFormatter.string(from: Date())
            
            let defaults = UserDefaults.standard
            defaults.set(deviceName, forKey: "ServerName")
            defaults.set(count, forKey: "MusicsCount")
            defaults.set(lastUpdate, forKey: "LastUpdate")
        }
    }
    
    func getDirectories() -> [MusicDirectory] {
        let sql = """
        SELECT
           \(DBConstants.TableDiretory.colRowId),
           \(DBConstants.TableDiretory.colDirName),
           \(DBConstants.TableDiretory.colDirPath)
        FROM
           \(DBConstants.TableDiretory.tableName)
        ORDER BY
           \(DBConstants.TableDiretory.colDirName)
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
    
    private func CreateTables() {
        createTableDirectories()
        createTableMusics()
        createTableArtists()
        createTableAlbuns()
        createTableGenres()
    }
    
    func addDirectory(dirPath: String) -> Bool{
        var result = false
        
        var queryStatement: OpaquePointer?
        let sql = "INSERT INTO \(DBConstants.TableDiretory.tableName) (\(DBConstants.TableDiretory.colDirPath)) VALUES (\"\(dirPath)\");"
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
    
    func deleteDirectory(dirName: String) -> Bool {
        var result = true
        
        var queryStatement: OpaquePointer?
        let sqlDeleteRowsTableDirs = "DELETE FROM \(DBConstants.TableDiretory.tableName) WHERE \(DBConstants.TableDiretory.colDirName) = \"\(dirName)\";"
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
    
    func musicExists(filePath: String) -> Bool {
        let sql = """
        SELECT
           *
        FROM
           \(DBConstants.TableMusic.tableName)
        WHERE
           \(DBConstants.TableMusic.colFilePath) = \"\(filePath)\"
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
    
    func AddMusic(filePath: String, musicTitle: String, artist: String, album: String, year: Int, track: Int, duration: Int, genre: String) -> Bool{
        let idArtist = getRowId(table: DBConstants.TableArtist.tableName, column1: DBConstants.TableArtist.colArtist, value1: artist)
        let idAlbum = getRowId(table: DBConstants.TableAlbum.tableName, column1: DBConstants.TableAlbum.colAlbum, value1: album, column2: DBConstants.TableAlbum.colYear, value2: String(year))
        let idGenre = getRowId(table: DBConstants.TableGenre.tableName, column1: DBConstants.TableGenre.colGenre, value1: genre)
        var result = false
        
        var queryStatement: OpaquePointer?
        let sql = "INSERT INTO \(DBConstants.TableMusic.tableName) (\(DBConstants.TableMusic.colFilePath), \(DBConstants.TableMusic.colIdArtist), \(DBConstants.TableMusic.colTrack), \(DBConstants.TableMusic.colDuration), \(DBConstants.TableMusic.colIdAlbum), \(DBConstants.TableMusic.colTitle), \(DBConstants.TableMusic.colIdGenre)) VALUES (\"\(filePath)\", \(idArtist), \(track), \(duration), \(idAlbum), \"\(musicTitle.replacingOccurrences(of: "\"", with: "'"))\", \(idGenre) );"
        if sqlite3_prepare_v2(self.database, sql, -1, &queryStatement, nil) == SQLITE_OK {
            if sqlite3_step(queryStatement) == SQLITE_DONE {
                result = true
            }
        }
        sqlite3_finalize(queryStatement)
        return result
    }
    
    private func createTableDirectories() {
        let sqlCreateTableDir = """
        CREATE TABLE IF NOT EXISTS \(DBConstants.TableDiretory.tableName) (
        \(DBConstants.TableDiretory.colDirPath) CHAR(255) PRIMARY KEY NOT NULL,
        \(DBConstants.TableDiretory.colDirName) CHAR(75));
        """
        if createTable(sql: sqlCreateTableDir) {
            
        }
    }
    
    private func createTableMusics() {
        let sqlCreateTableMusics = """
        CREATE TABLE IF NOT EXISTS \(DBConstants.TableMusic.tableName) (
        \(DBConstants.TableMusic.colFilePath) CHAR(255) PRIMARY KEY NOT NULL,
        \(DBConstants.TableMusic.colIdArtist) INT,
        \(DBConstants.TableMusic.colIdAlbum) INT,
        \(DBConstants.TableMusic.colDuration) INT,
        \(DBConstants.TableMusic.colTrack) INT,
        \(DBConstants.TableMusic.colTitle) CHAR(255),
        \(DBConstants.TableMusic.colIdGenre) INT);
        """
        if createTable(sql: sqlCreateTableMusics) {
            
        }
    }
    
    private func createTableArtists() {
        let sqlCreateTableArtists = """
        CREATE TABLE IF NOT EXISTS \(DBConstants.TableArtist.tableName) (
        \(DBConstants.TableArtist.colArtist) CHAR(255) PRIMARY KEY NOT NULL);
        """
        if createTable(sql: sqlCreateTableArtists) {
            
        }
    }
    
    private func createTableAlbuns() {
        let sqlCreateTableAlbuns = """
        CREATE TABLE IF NOT EXISTS \(DBConstants.TableAlbum.tableName) (
        \(DBConstants.TableAlbum.colAlbum) CHAR(255) PRIMARY KEY NOT NULL,
        \(DBConstants.TableAlbum.colYear) CHAR(4));
        """
        if createTable(sql: sqlCreateTableAlbuns) {
            
        }
    }
    
    private func createTableGenres() {
        let sqlCreateTableGenres = """
        CREATE TABLE IF NOT EXISTS \(DBConstants.TableGenre.tableName) (
        \(DBConstants.TableGenre.colGenre) CHAR(255) PRIMARY KEY NOT NULL);
        """
        if createTable(sql: sqlCreateTableGenres) {
            
        }
    }
    
    func getRowId(table: String, column1: String, value1: String, column2: String = "", value2: String = "") -> Int {
        var queryStatement: OpaquePointer?
        var sql = ""
        if !column2.isEmpty && !value2.isEmpty {
            sql = "SELECT RowId FROM \(table) WHERE \(column1) = \"\(value1.replacingOccurrences(of: "\"", with: "'"))\" AND \(column2) = \"\(value2.replacingOccurrences(of: "\"", with: "'"))\";"
        } else {
            sql = "SELECT RowId FROM \(table) WHERE \(column1) = \"\(value1.replacingOccurrences(of: "\"", with: "'"))\""
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
    
    private func updateRowsTableDirectories() -> Bool {
        var result = true
        
        var queryStatement: OpaquePointer?
        let sql1 = """
        SELECT
           \(DBConstants.TableDiretory.colRowId)
        FROM
           \(DBConstants.TableDiretory.tableName)
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
                let sql2 = "UPDATE \(DBConstants.TableDiretory.tableName) SET \(DBConstants.TableDiretory.colDirName) = \"Dir \(String(format: "%02d", count))\" WHERE \(DBConstants.TableDiretory.colRowId) = \(rowId);"
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
    
    private func deleteRowsTableMusics() -> Bool {
        return deleteRows(table: DBConstants.TableMusic.tableName)
    }
    
    private func deleteRowsTableArtists() -> Bool {
        return deleteRows(table: DBConstants.TableArtist.tableName )
    }
    
    private func deleteRowsTableAlbuns() -> Bool {
        return deleteRows(table: DBConstants.TableAlbum.tableName)
    }
    
    private func deleteRowsTableGenres() -> Bool {
        return deleteRows(table: DBConstants.TableGenre.tableName)
    }
    
    private func deleteRowsTableDirectories() -> Bool {
        return deleteRows(table: DBConstants.TableDiretory.tableName)
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
}

//class Database {
//

