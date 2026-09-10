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

// MARK: - LibraryViewModel
class LibraryViewModel: ObservableObject, MusicFilesDelegate {
    
    @Published var totalMusics: Int = 0
    @Published var totalTime: TimeInterval = 0
    @Published var isLoading: Bool = false
    
    @Published var directories = [MusicDirectory]()
    
    private var musicFiles = MusicFiles()
    
    init() {
        self.musicFiles.delegate = self
        self.directories = self.musicFiles.directories
        self.totalMusics = self.directories.reduce(0) { $0 + $1.musicCount }
        self.totalTime = self.directories.reduce(0.0) { $0 + $1.totalTime }
    }
    
    func addDirectory(dirPath: String) async {
        self.isLoading = true
        await self.musicFiles.addDirectory(dirPath: dirPath.removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? "")
        self.directories = self.musicFiles.directories
        self.totalMusics = self.directories.reduce(0) { $0 + $1.musicCount }
        self.totalTime = self.directories.reduce(0.0) { $0 + $1.totalTime }
        self.isLoading = false
    }
    
    func deleteDirectory(selection: UUID) async {
        self.isLoading = true
        if let dir = musicFiles.directories.first(where: { $0.id == selection }) {
            await self.musicFiles.deleteDirectory(dirName: dir.name)
            self.directories = self.musicFiles.directories
            self.totalMusics = self.directories.reduce(0) { $0 + $1.musicCount }
            self.totalTime = self.directories.reduce(0.0) { $0 + $1.totalTime }
            self.isLoading = false
        } else {
            self.isLoading = false
        }
        
    }

    func reloadDirectories() {
        self.directories = self.musicFiles.getDirectories()
        self.totalMusics = self.directories.reduce(0) { $0 + $1.musicCount }
        self.totalTime = self.directories.reduce(0.0) { $0 + $1.totalTime }
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

// MARK: - MusicFile
class MusicFiles {
    
    private var count = 0
    private let helper = DbHelper(path: DbConstants.databasePath)
    
    var delegate: MusicFilesDelegate?
    var directories = [MusicDirectory]()
    var musics = [Music]()
    var albuns = [Album]()
    var artists = [Artist]()
    var totalTime: TimeInterval = 0
    
    init() {
        if !createTablesIfNeeded() {
            print("Erro ao criar tabelas")
        }
        self.directories = getDirectories()
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
                self.saveServerInfo()
            }
        }
    }
    
    private func updateMusicsDatabase(completion: @escaping (Int?) -> ()) async {
        cleanMusicsTables()
        for dir in self.directories {
            var countDir = 0
            var totalTimeDir = 0.0
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
                                        let album = ((id3Tag?.frames[.album] as? ID3FrameWithStringContent)?.content ?? String()) as String
                                        let year = ((id3Tag?.frames[.recordingYear] as? ID3FrameWithIntegerContent)?.value ?? Int()) as Int
                                        let track = ((id3Tag?.frames[.trackPosition] as? ID3FramePartOfTotal)?.part ?? Int()) as Int
                                        let duration = await Id3TagUtils.getDuration(url: fileURL)
                                        let musicTitle = ((id3Tag?.frames[.title] as? ID3FrameWithStringContent)?.content ?? String()) as String
                                        let genre = ((id3Tag?.frames[.genre] as? ID3FrameGenre)?.description ?? String()) as String
                                        let filePath = fileURL.absoluteString
                                        
                                        var hasLyric = false
                                        if let frame = id3Tag?.frames[.unsynchronizedLyrics(.unknown)] {
                                            if let textFrame = frame as? ID3FrameWithStringContent {
                                                hasLyric = !textFrame.content.isEmpty
                                            }
                                        }
                                        
                                        if AddMusic(filePath: filePath,
                                                    musicTitle: musicTitle,
                                                    artist: artist,
                                                    album: album,
                                                    year: year,
                                                    track: track,
                                                    duration: duration,
                                                    genre: genre,
                                                    hasLyric: hasLyric) {
                                            
                                            if count % 49 == 0 {
                                                delegate?.musicLoading(musicsLoaded: count, totalTime: totalTime)
                                            }
                                            count += 1
                                            countDir += 1
                                            totalTime += Double(duration)
                                            totalTimeDir += Double(duration)
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
            if !updateDirData(dirPath: dir.path, countDir: countDir, totalTimeDir: totalTimeDir) {
                print("Falha ao atualizar diretório.")
            }
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
    
    func updateDirData(dirPath: String, countDir: Int, totalTimeDir: Double) -> Bool{
        let sql = "UPDATE \(DbConstants.TableDiretory.tableName) SET \(DbConstants.TableDiretory.colMusicsCount) = \(countDir), \(DbConstants.TableDiretory.colTotalTime) = \(totalTimeDir) WHERE \(DbConstants.TableDiretory.colDirPath) = \"\(dirPath)\";"
        if ((self.helper?.executeQuery(query: sql)) != nil) {
            return true
        }
        return false
    }
    
    func getDirectories() -> [MusicDirectory] {
        let sql = """
        SELECT
           \(DbConstants.TableDiretory.colDirId),
           \(DbConstants.TableDiretory.colDirName),
           \(DbConstants.TableDiretory.colDirPath),
           \(DbConstants.TableDiretory.colMusicsCount),
           \(DbConstants.TableDiretory.colTotalTime)
        FROM
           \(DbConstants.TableDiretory.tableName)
        ORDER BY
           \(DbConstants.TableDiretory.colDirName)
        """
        var dirList = [MusicDirectory]()
        var count = 0
        do {
            if let rows = try self.helper?.sql(query: sql) {
                for row in rows {
                    if
                        let dirName = row[DbConstants.TableDiretory.colDirName] as? String,
                        let dirPath = row[DbConstants.TableDiretory.colDirPath] as? String,
                        let musicsCount = row[DbConstants.TableDiretory.colMusicsCount] as? Int,
                        let totalTime = row[DbConstants.TableDiretory.colTotalTime] as? Double {
                        count += 1
                        dirList.append(MusicDirectory(name: dirName, path: dirPath, musicCount: musicsCount, totalTime: totalTime))
                    }
                }
            }
        } catch {
            print(error)
        }
        return dirList
    }
    
    func addDirectory(dirPath: String) -> Bool{
        let sql = "INSERT INTO \(DbConstants.TableDiretory.tableName) (\(DbConstants.TableDiretory.colDirPath),\(DbConstants.TableDiretory.colMusicsCount),\(DbConstants.TableDiretory.colTotalTime)) VALUES (\"\(dirPath)\",0, 0.0);"
        if ((self.helper?.executeQuery(query: sql)) != nil) {
            return updateRowsTableDirectories()
        }
        return false
    }
    
    func cleanMusicsTables() {
        if !deleteRowsTableAlbuns() {
            print("Falha ao deletar registros da tabela \"Albuns\".")
        }
        if !deleteRowsTableGenres() {
            print("Falha ao deletar registros da tabela \"Genres\".")
        }
        if !deleteRowsTableArtists() {
            print("Falha ao deletar registros da tabela \"Artists\".")
        }
        if !deleteRowsTableMusics() {
            print("Falha ao deletar registros da tabela \"Musics\".")
        }
    }
    
    func deleteDirectory(dirName: String) -> Bool {
        let sql = "DELETE FROM \(DbConstants.TableDiretory.tableName) WHERE \(DbConstants.TableDiretory.colDirName) = \"\(dirName)\";"
        if ((self.helper?.executeQuery(query: sql)) != nil) {
            return true
        }
        return false
    }
    
    func musicExists(filePath: String) -> Bool {
        let sql = """
        SELECT
           *
        FROM
           \(DbConstants.TableMusic.tableName)
        WHERE
           \(DbConstants.TableMusic.colFilePath) = \"\(filePath)\"
        """
        
        do {
            if let rows = try self.helper?.sql(query: sql) {
                return rows.count > 0
            }
        } catch {
            print(error)
        }
        return false
    }
    
    func AddMusic(filePath: String, musicTitle: String, artist: String, album: String, year: Int, track: Int, duration: Int, genre: String, hasLyric: Bool) -> Bool{
        let idArtist = getRowId(table: DbConstants.TableArtist.tableName, columnId: DbConstants.TableArtist.colArtistId, column1: DbConstants.TableArtist.colArtist, value1: artist)
        let idAlbum = getRowId(table: DbConstants.TableAlbum.tableName, columnId: DbConstants.TableAlbum.colAlbumId, column1: DbConstants.TableAlbum.colAlbum, value1: album, column2: DbConstants.TableAlbum.colYear, value2: String(year))
        let idGenre = getRowId(table: DbConstants.TableGenre.tableName, columnId: DbConstants.TableGenre.colGenreId, column1: DbConstants.TableGenre.colGenre, value1: genre)
        
        let sql = "INSERT INTO \(DbConstants.TableMusic.tableName) (\(DbConstants.TableMusic.colFilePath), \(DbConstants.TableMusic.colIdArtist), \(DbConstants.TableMusic.colTrack), \(DbConstants.TableMusic.colDuration), \(DbConstants.TableMusic.colIdAlbum), \(DbConstants.TableMusic.colTitle), \(DbConstants.TableMusic.colIdGenre), \(DbConstants.TableMusic.colHasLyrics)) VALUES (\"\(filePath)\", \(idArtist), \(track), \(duration), \(idAlbum), \"\(musicTitle.replacingOccurrences(of: "\"", with: "'"))\", \(idGenre), \(hasLyric ? 1 : 0) );"
        if ((self.helper?.executeQuery(query: sql)) != nil) {
            return true
        }
        return false
    }
    
    func createTablesIfNeeded() -> Bool {
        let statements = [
                    """
                    CREATE TABLE IF NOT EXISTS \(DbConstants.TableArtist.tableName) (
                    \(DbConstants.TableArtist.colArtistId) INTEGER PRIMARY KEY,
                    \(DbConstants.TableArtist.colArtist) TEXT NOT NULL UNIQUE);
                    """,
                    
                    """
                    CREATE TABLE IF NOT EXISTS \(DbConstants.TableAlbum.tableName) (
                    \(DbConstants.TableAlbum.colAlbumId) INTEGER PRIMARY KEY,
                    \(DbConstants.TableAlbum.colAlbum) TEXT NOT NULL,
                    \(DbConstants.TableAlbum.colYear) INTEGER, 
                    UNIQUE (\(DbConstants.TableAlbum.colAlbum), \(DbConstants.TableAlbum.colYear))
                    );
                    """,
                    
                    """
                    CREATE TABLE IF NOT EXISTS \(DbConstants.TableDiretory.tableName) (
                        \(DbConstants.TableDiretory.colDirId) INTEGER PRIMARY KEY,
                        \(DbConstants.TableDiretory.colDirPath) TEXT NOT NULL UNIQUE,
                        \(DbConstants.TableDiretory.colDirName) TEXT,
                        \(DbConstants.TableDiretory.colMusicsCount) INTEGER NOT NULL DEFAULT 0 CHECK (\(DbConstants.TableDiretory.colMusicsCount) >= 0),
                        \(DbConstants.TableDiretory.colTotalTime) REAL NOT NULL DEFAULT 0 CHECK (\(DbConstants.TableDiretory.colTotalTime) >= 0)
                    );
                    """,
                    
                    """
                    CREATE TABLE IF NOT EXISTS \(DbConstants.TableGenre.tableName) (
                    GenreId INTEGER PRIMARY KEY,
                    \(DbConstants.TableGenre.colGenre) TEXT NOT NULL UNIQUE);
                    """,
                    
                    """
                    CREATE TABLE IF NOT EXISTS \(DbConstants.TableMusic.tableName) (
                    \(DbConstants.TableMusic.colMusicId) INTEGER PRIMARY KEY,
                    \(DbConstants.TableMusic.colFilePath) TEXT NOT NULL UNIQUE,
                    \(DbConstants.TableMusic.colIdArtist) INTEGER NOT NULL REFERENCES \(DbConstants.TableArtist.tableName)(\(DbConstants.TableArtist.colArtistId)) ON DELETE RESTRICT,
                    \(DbConstants.TableMusic.colIdAlbum) INTEGER REFERENCES \(DbConstants.TableAlbum.tableName)(\(DbConstants.TableAlbum.colAlbumId)) ON DELETE SET NULL,
                    \(DbConstants.TableMusic.colTitle) TEXT NOT NULL,
                    \(DbConstants.TableMusic.colIdGenre) INTEGER REFERENCES \(DbConstants.TableGenre.tableName)(\(DbConstants.TableGenre.colGenreId)) ON DELETE SET NULL,
                    \(DbConstants.TableMusic.colDuration) INTEGER NOT NULL DEFAULT 0 CHECK (\(DbConstants.TableMusic.colDuration) >= 0),
                    \(DbConstants.TableMusic.colTrack) INTEGER CHECK (\(DbConstants.TableMusic.colTrack) >= 0),
                    \(DbConstants.TableMusic.colHasLyrics) INTEGER NOT NULL DEFAULT 0 CHECK (\(DbConstants.TableMusic.colHasLyrics) IN (0, 1))
                    );
                    """]
        
        var result = true
        for sql in statements {
            if let resultExec = self.helper?.executeQuery(query: sql) {
                result = result && resultExec
            }
        }
        return result
    }
    
    func getRowId(table: String, columnId: String, column1: String, value1: String, column2: String = "", value2: String = "") -> Int {
        var sql = ""
        if !column2.isEmpty && !value2.isEmpty {
            sql = "SELECT \(columnId) FROM \(table) WHERE \(column1) = \"\(value1.replacingOccurrences(of: "\"", with: "'"))\" AND \(column2) = \"\(value2.replacingOccurrences(of: "\"", with: "'"))\";"
        } else {
            sql = "SELECT \(columnId) FROM \(table) WHERE \(column1) = \"\(value1.replacingOccurrences(of: "\"", with: "'"))\""
        }
        do {
            if let rows = try self.helper?.sql(query: sql) {
                for row in rows {
                    if let result = row[columnId] as? Int {
                        return result
                    }
                }
            }
        } catch {
            print(error)
        }
        if column2 != "" && value2 != "" {
            sql = "INSERT INTO \(table) (\(column1), \(column2)) VALUES (\"\(value1.replacingOccurrences(of: "\"", with: "'"))\", \"\(value2.replacingOccurrences(of: "\"", with: "'"))\");"
        } else {
            sql = "INSERT INTO \(table) (\(column1)) VALUES (\"\(value1.replacingOccurrences(of: "\"", with: "'"))\");"
        }
        if ((self.helper?.executeQuery(query: sql)) != nil) {
            if !column2.isEmpty && !value2.isEmpty {
                sql = "SELECT \(columnId) FROM \(table) WHERE \(column1) = \"\(value1.replacingOccurrences(of: "\"", with: "'"))\" AND \(column2) = \"\(value2.replacingOccurrences(of: "\"", with: "'"))\";"
            } else {
                sql = "SELECT \(columnId) FROM \(table) WHERE \(column1) = \"\(value1.replacingOccurrences(of: "\"", with: "'"))\""
            }
            do {
                if let rows = try self.helper?.sql(query: sql) {
                    for row in rows {
                        if let result = row[columnId] as? Int {
                            return result
                        }
                    }
                }
            } catch {
                print(error)
            }
        }
        return 0
    }
    
    private func updateRowsTableDirectories() -> Bool {
        var result = true
        var rowIdList = [String]()
        let sql1 = """
        SELECT
           \(DbConstants.TableDiretory.colDirId)
        FROM
           \(DbConstants.TableDiretory.tableName)
        """
        do {
            if let rows = try self.helper?.sql(query: sql1) {
                for row in rows {
                    if let rowId = row[DbConstants.TableDiretory.colDirId] as? Int {
                        rowIdList.append(String(rowId))
                    }
                }
                if rowIdList.count > 0 {
                    var count = 1
                    for rowId in rowIdList {
                        let sql2 = "UPDATE \(DbConstants.TableDiretory.tableName) SET \(DbConstants.TableDiretory.colDirName) = \"Dir \(String(format: "%02d", count))\" WHERE \(DbConstants.TableDiretory.colDirId) = \(rowId);"
                        
                        if !((self.helper?.executeQuery(query: sql2)) != nil) {
                            result = false
                        }
                        count += 1
                    }
                }
                return result
            }
        } catch {
            print(error)
        }
        return result
        
    }
    
    private func deleteRowsTableMusics() -> Bool {
        let sql = "DELETE FROM \(DbConstants.TableMusic.tableName);"
        if ((self.helper?.executeQuery(query: sql)) != nil) {
            return true
        }
        return false
    }
    
    private func deleteRowsTableArtists() -> Bool {
        let sql = "DELETE FROM \(DbConstants.TableArtist.tableName);"
        if ((self.helper?.executeQuery(query: sql)) != nil) {
            return true
        }
        return false
    }
    
    private func deleteRowsTableAlbuns() -> Bool {
        let sql = "DELETE FROM \(DbConstants.TableAlbum.tableName);"
        if ((self.helper?.executeQuery(query: sql)) != nil) {
            return true
        }
        return false
    }
    
    private func deleteRowsTableGenres() -> Bool {
        let sql = "DELETE FROM \(DbConstants.TableGenre.tableName);"
        if ((self.helper?.executeQuery(query: sql)) != nil) {
            return true
        }
        return false
    }
    
    private func deleteRowsTableDirectories() -> Bool {
        let sql = "DELETE FROM \(DbConstants.TableDiretory.tableName);"
        if ((self.helper?.executeQuery(query: sql)) != nil) {
            return true
        }
        return false
    }
}
