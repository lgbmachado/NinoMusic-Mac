//
//  TagEditorViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Baptista Machado on 06/02/26.
//

import SwiftUI
import ID3TagEditor

enum EditOrigin {
    case fileDir
    case library
}

enum MusicExportResult {
    case exported
    case exportedAndRemovedOriginal
    case exportedButCouldNotRemoveOriginal
    case alreadyExists
    case failed

    var succeeded: Bool {
        switch self {
        case .exported, .exportedAndRemovedOriginal, .exportedButCouldNotRemoveOriginal:
            return true
        case .alreadyExists, .failed:
            return false
        }
    }
}

extension Notification.Name {
    static let musicLibraryDidChange = Notification.Name("musicLibraryDidChange")
}

class TagEditorViewModel: BaseViewModel {
    @Published var musicsLibrary: [Music] = []
    @Published var musicsFileDir: [Music] = []
    @Published var libraryDirectories: [MusicDirectory] = []
    @Published var musicSelectedDraft: Music = Music.emptyMusic
    @Published var musicLyric: String = String()
    @Published var musicLyricDraft: String = String()
    @Published private(set) var coverRevision = 0
    
    var origin: EditOrigin = .fileDir
    
    var selectedCaseTag: CaseKind {
        get {
            let defaults = UserDefaults.standard
            return CaseKind(rawValue: defaults.string(forKey: "CaseKind") ?? "") ?? .capitalized
        }
        set(newVal) {
            let defaults = UserDefaults.standard
            defaults.set(newVal.rawValue, forKey: "CaseKind")
        }
    }
    
    var selectedCaseFileName: CaseKind {
        get {
            let defaults = UserDefaults.standard
            return CaseKind(rawValue: defaults.string(forKey: "CaseKindFileName") ?? "") ?? .capitalized
        }
        set(newVal) {
            let defaults = UserDefaults.standard
            defaults.set(newVal.rawValue, forKey: "CaseKindFileName")
        }
    }
    
    var genresAvaiables: [String] {
        get {
            let defaults = UserDefaults.standard
            return defaults.stringArray(forKey: "GenresAvaiables") ?? Id3TagUtils.genresAvaiables()
        }
        set(newVal) {
            let defaults = UserDefaults.standard
            defaults.set(newVal, forKey: "GenresAvaiables")
        }
    }
    
    static let fileNameMaskFields = [
        "{track}",
        "{track:02}",
        "{artist}",
        "{title}",
        "{album}",
        "{year}",
        "{genre}"
    ]

    func loadLibraryDirectories() {
        let query = """
            SELECT
                \(DbConstants.TableDiretory.colDirName),
                \(DbConstants.TableDiretory.colDirPath),
                \(DbConstants.TableDiretory.colMusicsCount),
                \(DbConstants.TableDiretory.colTotalTime)
            FROM \(DbConstants.TableDiretory.tableName)
            ORDER BY \(DbConstants.TableDiretory.colDirName)
            """

        do {
            libraryDirectories = try helper?.sql(query: query).compactMap { row in
                guard let name = row[DbConstants.TableDiretory.colDirName] as? String,
                      let path = row[DbConstants.TableDiretory.colDirPath] as? String,
                      let musicCount = row[DbConstants.TableDiretory.colMusicsCount] as? Int,
                      let totalTime = row[DbConstants.TableDiretory.colTotalTime] as? Double else {
                    return nil
                }
                return MusicDirectory(name: name, path: path, musicCount: musicCount, totalTime: totalTime)
            } ?? []
        } catch {
            print(error)
            libraryDirectories = []
        }
    }

    func reloadMusics() async {
        let sql = """
            SELECT
               \(DbConstants.TableMusic.tableName).\(DbConstants.TableMusic.colMusicId),
               \(DbConstants.TableArtist.colArtist),
               \(DbConstants.TableMusic.colTitle),
               \(DbConstants.TableMusic.colTrack),
               \(DbConstants.TableAlbum.colAlbum),
               \(DbConstants.TableGenre.colGenre),
               \(DbConstants.TableMusic.colDuration),
               \(DbConstants.TableAlbum.colYear),
               \(DbConstants.TableMusic.colFilePath),
               \(DbConstants.TableMusic.colHasLyrics)
            FROM
               \(DbConstants.TableMusic.tableName)
               INNER JOIN \(DbConstants.TableArtist.tableName) ON \(DbConstants.TableArtist.tableName).\(DbConstants.TableArtist.colArtistId) = \(DbConstants.TableMusic.colIdArtist)
               INNER JOIN \(DbConstants.TableAlbum.tableName) ON \(DbConstants.TableAlbum.tableName).\(DbConstants.TableAlbum.colAlbumId) = \(DbConstants.TableMusic.colIdAlbum)
               INNER JOIN \(DbConstants.TableGenre.tableName) ON \(DbConstants.TableGenre.tableName).\(DbConstants.TableGenre.colGenreId) = \(DbConstants.TableMusic.colIdGenre)
            ORDER BY
               \(DbConstants.TableMusic.colTitle),
               \(DbConstants.TableArtist.colArtist)
            """
        await MainActor.run {
            self.isLoading = true
        }
        
        let musicList = await withCheckedContinuation { (continuation: CheckedContinuation<[Music], Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                var musicList = [Music]()
                var seq = 0
                
                do {
                    if let rows = try self.helper?.sql(query: sql) {
                        for row in rows {
                            seq += 1
                            if
                                let idServer = row[DbConstants.TableMusic.colMusicId] as? Int,
                                let artist = row[DbConstants.TableArtist.colArtist] as? String,
                                let album = row[DbConstants.TableAlbum.colAlbum] as? String,
                                let year = row[DbConstants.TableAlbum.colYear] as? Int,
                                let track = row[DbConstants.TableMusic.colTrack] as? Int,
                                let musicTitle = row[DbConstants.TableMusic.colTitle] as? String,
                                let genre = row[DbConstants.TableGenre.colGenre] as? String,
                                let duration = row[DbConstants.TableMusic.colDuration] as? Int,
                                let filePath = row[DbConstants.TableMusic.colFilePath] as? String,
                                let hasLyric = row[DbConstants.TableMusic.colHasLyrics] as? Int
                            {
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
                                                       hasLyric: hasLyric == 1))
                            }
                        }
                    }
                } catch {
                    print(error)
                }
                
                continuation.resume(returning: musicList)
            }
        }
        
        await MainActor.run {
            self.musicsLibrary = musicList
            self.isLoading = false
        }
    }
    
    private func loadMusicLyric(for item: Music) {
        let fileHasLyrics = item.hasLyric || Id3TagUtils.hasLyrics(path: item.filePath)
        self.musicSelected.hasLyric = fileHasLyrics
        self.musicLyric = fileHasLyrics ? (Id3TagUtils.getLyrics(path: item.filePath) ?? "") : ""
        self.musicLyricDraft = self.musicLyric
    }

    private func fileURL(for path: String) -> URL? {
        if let url = URL(string: path), url.isFileURL {
            return url
        }

        let decodedPath = path.removingPercentEncoding ?? path
        return URL(fileURLWithPath: decodedPath)
    }

    private func pictureFormat(for imageData: Data) -> ID3PictureFormat? {
        if imageData.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) {
            return .png
        }
        if imageData.starts(with: [0xFF, 0xD8, 0xFF]) {
            return .jpeg
        }
        return nil
    }

    func setIdLibrarySelection(selection: Music.ID) {
        origin = .library
        self.idMusicSelected = selection
        if let item = self.musicsLibrary.first(where: { $0.id == self.idMusicSelected }) {
            self.idMusicSelected = item.id
            self.musicSelected = item
            self.fileSelected = String((item.filePath as NSString).lastPathComponent).removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? ""
            self.loadMusicLyric(for: item)
        } else {
            self.musicSelected = Music.emptyMusic
        }
        self.musicSelectedDraft = self.musicSelected
        refreshCover()
    }
    
    func setIdFilesSelection(selection: Music.ID) {
        origin = .fileDir
        self.idMusicSelected = selection
        if let item = self.musicsFileDir.first(where: { $0.id == self.idMusicSelected }) {
            self.idMusicSelected = item.id
            self.musicSelected = item
            self.fileSelected = String((item.filePath as NSString).lastPathComponent).removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? ""
            self.loadMusicLyric(for: item)
        } else {
            self.musicSelected = Music.emptyMusic
        }
        self.musicSelectedDraft = self.musicSelected
        refreshCover()
    }
    
    func AddFile(url: URL) async {
        if url.pathExtension.uppercased() == "MP3" {
            let music = await GetMusicTags(fileURL: url)
            self.musicsFileDir.append(music)
        }
    }
    
    func AddFolder(url: URL) async {
        if let enumFiles = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            var seq = 0
            for case let fileURL as URL in enumFiles {
                await self.AddFile(url: fileURL)
            }
        }
    }
    
    private func GetMusicTags(fileURL: URL) async -> Music {
        let id3TagEditor: ID3TagEditor = ID3TagEditor()
        do {
            let id3Tag = try id3TagEditor.read(from: fileURL.path)
            
            let artist = ((id3Tag?.frames[.artist] as? ID3FrameWithStringContent)?.content ?? String()) as String
            let album = ((id3Tag?.frames[.album] as? ID3FrameWithStringContent)?.content ?? String()) as String
            let year = (id3Tag?.frames[.recordingYear] as? ID3FrameWithIntegerContent)?.value
                ?? (id3Tag?.frames[.recordingDateTime] as? ID3FrameRecordingDateTime)?.recordingDateTime.date?.year
                ?? 0
            let track = ((id3Tag?.frames[.trackPosition] as? ID3FramePartOfTotal)?.part ?? Int()) as Int
            let duration = await Id3TagUtils.getDuration(url: fileURL)
            let musicTitle = ((id3Tag?.frames[.title] as? ID3FrameWithStringContent)?.content ?? String()) as String
            let genre = ((id3Tag?.frames[.genre] as? ID3FrameGenre)?.description ?? String()) as String
            let filePath = fileURL.absoluteString
            
            let hasLyric = !(Id3TagUtils.lyrics(in: id3Tag)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            return Music(id: UUID(),
                         seq: 0,
                         idServer: 0,
                         artist: artist,
                         album: album,
                         year: year,
                         track: track,
                         musicTitle: musicTitle,
                         genre: genre,
                         duration: 0,
                         filePath: filePath,
                         hasLyric: hasLyric)
        }
        catch {
            print(error)
            return Music.emptyMusic
        }
    }


    func SetMusicTags(coverImagePath: String) -> Bool {
        guard let musicURL = fileURL(for: self.musicSelectedDraft.filePath) else {
            return false
        }

        let id3TagEditor: ID3TagEditor = ID3TagEditor()
        let currentTag = try? id3TagEditor.read(from: musicURL.path)

        do {
            var frames = currentTag?.frames ?? [:]
            var expectedCoverData: Data?
            frames[.title] = ID3FrameWithStringContent(content: self.musicSelectedDraft.musicTitle)
            frames[.artist] = ID3FrameWithStringContent(content: self.musicSelectedDraft.artist)
            frames[.album] = ID3FrameWithStringContent(content: self.musicSelectedDraft.album)
            if currentTag?.properties.version == .version4 {
                let currentDateTime = (frames[.recordingDateTime] as? ID3FrameRecordingDateTime)?.recordingDateTime
                let recordingDate = RecordingDate(day: currentDateTime?.date?.day,
                                                  month: currentDateTime?.date?.month,
                                                  year: self.musicSelectedDraft.year)
                frames[.recordingDateTime] = ID3FrameRecordingDateTime(
                    recordingDateTime: RecordingDateTime(date: recordingDate, time: currentDateTime?.time)
                )
                frames.removeValue(forKey: .recordingYear)
            } else {
                frames[.recordingYear] = ID3FrameWithIntegerContent(value: self.musicSelectedDraft.year)
            }
            frames[.trackPosition] = ID3FramePartOfTotal(part: self.musicSelectedDraft.track, total: nil)
            frames[.genre] = ID3FrameGenre(genre: nil, description: self.musicSelectedDraft.genre)

            let trimmedLyric = self.musicLyricDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            for frameName in Array(frames.keys) {
                if case .unsynchronizedLyrics = frameName {
                    frames.removeValue(forKey: frameName)
                }
            }
            if !trimmedLyric.isEmpty {
                frames[.unsynchronizedLyrics(.eng)] = ID3FrameWithLocalizedContent(
                    language: .eng,
                    contentDescription: "Lyric - \(self.musicSelectedDraft.musicTitle)",
                    content: trimmedLyric
                )
            }

            if !coverImagePath.isEmpty {
                guard let imageURL = fileURL(for: coverImagePath),
                      let imageData = try? Data(contentsOf: imageURL),
                      let format = pictureFormat(for: imageData) else {
                    return false
                }
                expectedCoverData = imageData

                frames[.attachedPicture(.frontCover)] = ID3FrameAttachedPicture(
                    picture: imageData,
                    type: .frontCover,
                    format: format
                )
            }

            let id3Tag: ID3Tag
            switch currentTag?.properties.version {
            case .version2:
                id3Tag = ID32v2TagBuilder().build()
            case .version4:
                id3Tag = ID32v4TagBuilder().build()
            default:
                id3Tag = ID32v3TagBuilder().build()
            }
            id3Tag.frames = frames
            try id3TagEditor.write(tag: id3Tag, to: musicURL.path)

            guard let savedTag = try id3TagEditor.read(from: musicURL.path) else {
                return false
            }
            let savedYear = (savedTag.frames[.recordingYear] as? ID3FrameWithIntegerContent)?.value
                ?? (savedTag.frames[.recordingDateTime] as? ID3FrameRecordingDateTime)?.recordingDateTime.date?.year
            let savedCoverData = Id3TagUtils.attachedPictureData(in: savedTag)
            let readableCoverData = Id3TagUtils.coverImageData(path: musicURL.path)
            guard
                  (savedTag.frames[.title] as? ID3FrameWithStringContent)?.content == self.musicSelectedDraft.musicTitle,
                  (savedTag.frames[.artist] as? ID3FrameWithStringContent)?.content == self.musicSelectedDraft.artist,
                  (savedTag.frames[.album] as? ID3FrameWithStringContent)?.content == self.musicSelectedDraft.album,
                  savedYear == self.musicSelectedDraft.year,
                  (savedTag.frames[.trackPosition] as? ID3FramePartOfTotal)?.part == self.musicSelectedDraft.track,
                  expectedCoverData == nil || savedCoverData.contains(expectedCoverData!) || readableCoverData == expectedCoverData else {
                return false
            }

            var savedMusic = self.musicSelectedDraft
            savedMusic.hasLyric = !trimmedLyric.isEmpty
            self.musicSelected = savedMusic
            self.musicSelectedDraft = savedMusic
            self.musicLyric = trimmedLyric
            self.musicLyricDraft = trimmedLyric
            updateCachedMusic(savedMusic)
            refreshCover()
            return true
        } catch {
            print(error)
            return false
        }
    }

    private func updateCachedMusic(_ music: Music) {
        if let index = musicsFileDir.firstIndex(where: { $0.id == music.id }) {
            musicsFileDir[index] = music
        }
        if let index = musicsLibrary.firstIndex(where: { $0.id == music.id }) {
            musicsLibrary[index] = music
        }
    }

    private func refreshCover() {
        Id3TagUtils.invalidateCoverCache()
        coverRevision += 1
    }

    func saveCover(coverImageUrl: URL) -> Bool {
        let id3TagEditor = ID3TagEditor()
        guard let musicURL = fileURL(for: self.musicSelected.filePath) else {
            return false
        }

        func writeCoverData(_ imageData: Data, format: ID3PictureFormat) throws {
            let extensionStr = (format == .jpeg) ? "jpg" : "png"
            let imageOutputURL = coverImageUrl
                .deletingPathExtension()
                .appendingPathExtension(extensionStr)
            try imageData.write(to: imageOutputURL)
        }

        func saveReadableCoverFallback() -> Bool {
            guard let imageData = Id3TagUtils.coverImageData(path: musicURL.path),
                  let format = pictureFormat(for: imageData) else {
                return false
            }
            do {
                try writeCoverData(imageData, format: format)
                return true
            } catch {
                return false
            }
        }

        do {
            if let id3Tag = try id3TagEditor.read(from: musicURL.path) {
                if let artworkFrame = Id3TagUtils.firstAttachedPicture(in: id3Tag) {
                    let imageData = artworkFrame.picture
                    let format = artworkFrame.format
                    try writeCoverData(imageData, format: format)
                    
                    return true
                } else {
                    return saveReadableCoverFallback()
                }
            } else {
                return saveReadableCoverFallback()
            }
            
        } catch {
            return saveReadableCoverFallback()
        }
    }

    func fileNamePreview(mask: String) -> String {
        let fileExtension = fileURL(for: musicSelectedDraft.filePath)?.pathExtension ?? "mp3"
        let fileName = fileName(from: mask, music: musicSelectedDraft)
        return fileName.isEmpty ? "" : "\(fileName).\(fileExtension)"
    }

    func renameSelectedMusicFile(using mask: String) -> Bool {
        guard let sourceURL = fileURL(for: musicSelected.filePath),
              FileManager.default.fileExists(atPath: sourceURL.path) else {
            return false
        }

        let fileName = fileName(from: mask, music: musicSelectedDraft)
        guard !fileName.isEmpty else {
            return false
        }

        let destinationURL = sourceURL
            .deletingLastPathComponent()
            .appendingPathComponent(fileName)
            .appendingPathExtension(sourceURL.pathExtension)

        guard sourceURL.standardizedFileURL != destinationURL.standardizedFileURL,
              !FileManager.default.fileExists(atPath: destinationURL.path) else {
            return false
        }

        do {
            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)

            if musicSelected.idServer > 0 {
                let newFilePath = destinationURL.absoluteString.replacingOccurrences(of: "'", with: "''")
                let query = """
                    UPDATE \(DbConstants.TableMusic.tableName)
                    SET \(DbConstants.TableMusic.colFilePath) = '\(newFilePath)'
                    WHERE \(DbConstants.TableMusic.colMusicId) = \(musicSelected.idServer)
                    """
                guard helper?.executeQuery(query: query) == true else {
                    try? FileManager.default.moveItem(at: destinationURL, to: sourceURL)
                    return false
                }
            }

            var renamedMusic = musicSelectedDraft
            renamedMusic.filePath = destinationURL.absoluteString
            musicSelected = renamedMusic
            musicSelectedDraft = renamedMusic
            fileSelected = destinationURL.lastPathComponent
            musicsFileDir = musicsFileDir.map { $0.id == renamedMusic.id ? renamedMusic : $0 }
            musicsLibrary = musicsLibrary.map { $0.id == renamedMusic.id ? renamedMusic : $0 }
            musicPlayerViewModel.setMusicSelected(music: renamedMusic)
            return true
        } catch {
            print(error)
            return false
        }
    }

    func exportSelectedMusic(to libraryPath: String, deleteOriginal: Bool) async -> MusicExportResult {
        guard let sourceURL = fileURL(for: musicSelectedDraft.filePath),
              FileManager.default.fileExists(atPath: sourceURL.path),
              let library = libraryDirectories.first(where: { $0.path == libraryPath }) else {
            return .failed
        }

        let artistDirectory = sanitizedPathComponent(musicSelectedDraft.artist, fallback: "Artista desconhecido")
        let albumDirectory = sanitizedPathComponent(musicSelectedDraft.album, fallback: "Album desconhecido")
        let destinationDirectory = URL(fileURLWithPath: library.path)
            .appendingPathComponent(artistDirectory, isDirectory: true)
            .appendingPathComponent(albumDirectory, isDirectory: true)
        let destinationURL = destinationDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        let exportedMusic = MusicFiles()
        let destinationFilePath = destinationURL.absoluteString

        guard sourceURL.standardizedFileURL != destinationURL.standardizedFileURL,
              !FileManager.default.fileExists(atPath: destinationURL.path),
              !exportedMusic.musicExists(filePath: destinationFilePath) else {
            return .alreadyExists
        }

        guard SetMusicTags(coverImagePath: "") else {
            return .failed
        }

        do {
            try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

            let duration = await Id3TagUtils.getDuration(url: destinationURL)
        guard exportedMusic.AddMusic(filePath: destinationFilePath,
                                         musicTitle: musicSelectedDraft.musicTitle,
                                         artist: musicSelectedDraft.artist,
                                         album: musicSelectedDraft.album,
                                         year: musicSelectedDraft.year,
                                         track: musicSelectedDraft.track,
                                         duration: duration,
                                         genre: musicSelectedDraft.genre,
                                         hasLyric: !musicLyricDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) else {
                try? FileManager.default.removeItem(at: destinationURL)
                return .failed
            }

            let escapedPath = library.path.replacingOccurrences(of: "\"", with: "\"\"")
            let updateQuery = """
                UPDATE \(DbConstants.TableDiretory.tableName)
                SET \(DbConstants.TableDiretory.colMusicsCount) = \(DbConstants.TableDiretory.colMusicsCount) + 1,
                    \(DbConstants.TableDiretory.colTotalTime) = \(DbConstants.TableDiretory.colTotalTime) + \(Double(duration))
                WHERE \(DbConstants.TableDiretory.colDirPath) = "\(escapedPath)"
                """
            guard helper?.executeQuery(query: updateQuery) == true else {
                try? FileManager.default.removeItem(at: destinationURL)
                return .failed
            }

            await reloadMusics()
            loadLibraryDirectories()
            NotificationCenter.default.post(name: .musicLibraryDidChange, object: nil)

            guard deleteOriginal && origin == .fileDir else {
                return .exported
            }
            do {
                try FileManager.default.removeItem(at: sourceURL)
                musicsFileDir.removeAll { $0.id == musicSelectedDraft.id }
                idMusicSelected = nil
                musicSelected = .emptyMusic
                musicSelectedDraft = .emptyMusic
                fileSelected = ""
                musicLyric = ""
                musicLyricDraft = ""
                refreshCover()
                return .exportedAndRemovedOriginal
            } catch {
                print(error)
                return .exportedButCouldNotRemoveOriginal
            }
        } catch {
            print(error)
            return .failed
        }
    }

    private func fileName(from mask: String, music: Music) -> String {
        let replacements = [
            "artist": music.artist,
            "title": music.musicTitle,
            "album": music.album,
            "year": music.year > 0 ? String(music.year) : "",
            "genre": music.genre
        ]
        let pattern = #"\{(track|artist|title|album|year|genre)(?::(0\d+))?\}"#
        guard let regularExpression = try? NSRegularExpression(pattern: pattern) else {
            return sanitizedFileName(mask)
        }
        let range = NSRange(mask.startIndex..., in: mask)

        var result = mask
        for match in regularExpression.matches(in: mask, range: range).reversed() {
            guard let tokenRange = Range(match.range(at: 1), in: mask) else {
                continue
            }

            let token = String(mask[tokenRange])
            let value: String
            if token == "track" {
                if let formatRange = Range(match.range(at: 2), in: mask),
                   let width = Int(mask[formatRange]) {
                    value = String(format: "%0\(width)d", music.track)
                } else {
                    value = music.track > 0 ? String(music.track) : ""
                }
            } else {
                value = replacements[token] ?? ""
            }

            if let fullRange = Range(match.range, in: result) {
                result.replaceSubrange(fullRange, with: value)
            }
        }
        switch self.selectedCaseFileName {
            case .uppercase:
                result = result.uppercased()
            case .lowercase:
                result = result.lowercased()
            case .capitalized:
                result = result.capitalized
            case .none:
                break
            }
        return sanitizedFileName(result)
    }

    private func sanitizedFileName(_ fileName: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/:\\")
            .union(.controlCharacters)
        let sanitized = fileName.components(separatedBy: invalidCharacters).joined(separator: "-")
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func sanitizedPathComponent(_ component: String, fallback: String) -> String {
        let sanitized = sanitizedFileName(component)
        return sanitized.isEmpty ? fallback : sanitized
    }


    
    func GetCaseKind() -> CaseKind {
        let defaults = UserDefaults.standard
        return CaseKind(rawValue: defaults.string(forKey: "CaseKind") ?? "capitalized") ?? .capitalized
    }
    
    func SetCaseKind(newValue: String) {
        let defaults = UserDefaults.standard
        defaults.set(newValue , forKey: "CaseKind")
    }
}

private extension Array where Element == Music {
    func hasCommon(_ keyPath: KeyPath<Music, Int>) -> Bool {
        guard let firstValue = first?[keyPath: keyPath] else {
            return false
        }
        
        return allSatisfy { $0[keyPath: keyPath] == firstValue }
    }
    
    func hasCommon(_ keyPath: KeyPath<Music, String>) -> Bool {
        guard let firstValue = first?[keyPath: keyPath] else {
            return false
        }
        
        return allSatisfy { $0[keyPath: keyPath] == firstValue }
    }
    
    func commonString(_ keyPath: KeyPath<Music, String>) -> String {
        guard let firstValue = first?[keyPath: keyPath] else {
            return ""
        }
        
        return allSatisfy { $0[keyPath: keyPath] == firstValue } ? firstValue : ""
    }
    
    func commonInt(_ keyPath: KeyPath<Music, Int>, fallback: Int) -> Int {
        guard let firstValue = first?[keyPath: keyPath] else {
            return fallback
        }
        
        return allSatisfy { $0[keyPath: keyPath] == firstValue } ? firstValue : fallback
    }
}

