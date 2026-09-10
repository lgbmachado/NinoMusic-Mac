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
    
    var origin: EditOrigin = .fileDir
    
    var selectedCase: CaseKind {
        get {
            let defaults = UserDefaults.standard
            return CaseKind(rawValue: defaults.string(forKey: "CaseKind") ?? "") ?? .capitalized
        }
        set(newVal) {
            let defaults = UserDefaults.standard
            defaults.set(newVal.rawValue, forKey: "CaseKind")
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

    func setIdLibrarySelection(selection: Music.ID) {
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
    }
    
    func setIdFilesSelection(selection: Music.ID) {
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
            let year = ((id3Tag?.frames[.recordingYear] as? ID3FrameWithIntegerContent)?.value ?? Int()) as Int
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
            var builder = ID32v3TagBuilder()
                .title(frame: ID3FrameWithStringContent(content: self.musicSelectedDraft.musicTitle))
                .artist(frame: ID3FrameWithStringContent(content: self.musicSelectedDraft.artist))
                .album(frame: ID3FrameWithStringContent(content: self.musicSelectedDraft.album))
                .recordingYear(frame: ID3FrameWithIntegerContent(value: self.musicSelectedDraft.year))
                .trackPosition(frame: ID3FramePartOfTotal(part: self.musicSelectedDraft.track, total: nil))
                .genre(frame: .init(genre: nil, description: self.musicSelectedDraft.genre))

            let trimmedLyric = self.musicLyricDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedLyric.isEmpty {
                builder = builder.unsynchronisedLyrics(language: .eng,
                                                       frame: ID3FrameWithLocalizedContent(
                                                        language: ID3FrameContentLanguage.eng,
                                                        contentDescription: "Lyric - \(self.musicSelectedDraft.musicTitle)",
                                                        content: trimmedLyric))
            }

            if !coverImagePath.isEmpty {
                let imageURL = URL(fileURLWithPath: coverImagePath.removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? coverImagePath)

                if let imageData = try? Data(contentsOf: imageURL) {
                    let format: ID3PictureFormat = imageURL.pathExtension.lowercased() == "png" ? .png : .jpeg

                    let coverFrame = ID3FrameAttachedPicture(
                        picture: imageData,
                        type: .frontCover,
                        format: format
                    )

                    builder = builder.attachedPicture(pictureType: .frontCover, frame: coverFrame)
                }
            } else {
                if let existingCoverFrame = currentTag?.frames[.attachedPicture(.frontCover)] as? ID3FrameAttachedPicture {
                    builder = builder.attachedPicture(pictureType: .frontCover, frame: existingCoverFrame)
                }
            }

            let id3Tag = builder.build()
            try id3TagEditor.write(tag: id3Tag, to: musicURL.path)

            self.musicSelected.hasLyric = !trimmedLyric.isEmpty
            self.musicSelectedDraft.hasLyric = !trimmedLyric.isEmpty
            self.musicLyric = trimmedLyric
            return true
        } catch {
            print(error)
            return false
        }
    }

    func saveCover(coverImageUrl: URL) -> Bool {
        let id3TagEditor = ID3TagEditor()
        do {
            guard let musicURL = fileURL(for: self.musicSelected.filePath) else {
                return false
            }

            if let id3Tag = try id3TagEditor.read(from: musicURL.path) {
                if let artworkFrame = id3Tag.frames[.attachedPicture(.frontCover)] as? ID3FrameAttachedPicture {
                    let imageData = artworkFrame.picture
                    let format = artworkFrame.format
                    let extensionStr = (format == .jpeg) ? "jpg" : "png"
                    let imageOutputURL = coverImageUrl
                        .deletingPathExtension()
                        .appendingPathExtension(extensionStr)
                    try imageData.write(to: imageOutputURL)
                    
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
            
        } catch {
            return false
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

    func exportSelectedMusic(to libraryPath: String) async -> Bool {
        guard let sourceURL = fileURL(for: musicSelectedDraft.filePath),
              FileManager.default.fileExists(atPath: sourceURL.path),
              let library = libraryDirectories.first(where: { $0.path == libraryPath }) else {
            return false
        }

        guard SetMusicTags(coverImagePath: "") else {
            return false
        }

        let artistDirectory = sanitizedPathComponent(musicSelectedDraft.artist, fallback: "Artista desconhecido")
        let albumDirectory = sanitizedPathComponent(musicSelectedDraft.album, fallback: "Album desconhecido")
        let destinationDirectory = URL(fileURLWithPath: library.path)
            .appendingPathComponent(artistDirectory, isDirectory: true)
            .appendingPathComponent(albumDirectory, isDirectory: true)
        let destinationURL = destinationDirectory.appendingPathComponent(sourceURL.lastPathComponent)

        guard !FileManager.default.fileExists(atPath: destinationURL.path) else {
            return false
        }

        do {
            try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)

            let duration = await Id3TagUtils.getDuration(url: destinationURL)
            let exportedMusic = MusicFiles()
            let filePath = destinationURL.absoluteString
            guard !exportedMusic.musicExists(filePath: filePath),
                  exportedMusic.AddMusic(filePath: filePath,
                                         musicTitle: musicSelectedDraft.musicTitle,
                                         artist: musicSelectedDraft.artist,
                                         album: musicSelectedDraft.album,
                                         year: musicSelectedDraft.year,
                                         track: musicSelectedDraft.track,
                                         duration: duration,
                                         genre: musicSelectedDraft.genre,
                                         hasLyric: !musicLyricDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) else {
                try? FileManager.default.removeItem(at: destinationURL)
                return false
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
                return false
            }

            await reloadMusics()
            loadLibraryDirectories()
            NotificationCenter.default.post(name: .musicLibraryDidChange, object: nil)
            return true
        } catch {
            print(error)
            return false
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

