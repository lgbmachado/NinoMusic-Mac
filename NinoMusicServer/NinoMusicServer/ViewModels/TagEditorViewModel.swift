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

class TagEditorViewModel: BaseViewModel {
    @Published var musicsLibrary: [Music] = []
    @Published var musicsFileDir: [Music] = []
    @Published var musicSelectedDraft: Music = Music.emptyMusic
    @Published var musicLyric: String = String()
    
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
    
    func setIdLibrarySelection(selection: Music.ID) {
        self.idMusicSelected = selection
        if let item = self.musicsLibrary.first(where: { $0.id == self.idMusicSelected }) {
            self.idMusicSelected = item.id
            self.musicSelected = item
            self.fileSelected = String((item.filePath as NSString).lastPathComponent).removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? ""
            if self.musicSelected.hasLyric {
                self.musicLyric = Id3TagUtils.getLyrics(path: item.filePath) ?? ""
            } else {
                self.musicLyric = ""
            }
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
            if self.musicSelected.hasLyric {
                self.musicLyric = Id3TagUtils.getLyrics(path: item.filePath) ?? ""
            } else {
                self.musicLyric = ""
            }
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
            let id3Tag = try id3TagEditor.read(from: fileURL.path().removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? "")
            
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
        if let musicUrl = URL(string: self.musicSelectedDraft.filePath.removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? "") {
            let id3TagEditor: ID3TagEditor = ID3TagEditor()
            let currentTag = try? id3TagEditor.read(from: musicUrl.absoluteString.removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? "")
            
            do {
                var builder = ID32v3TagBuilder()
                    .title(frame: ID3FrameWithStringContent(content: self.musicSelectedDraft.musicTitle))
                    .artist(frame: ID3FrameWithStringContent(content: self.musicSelectedDraft.artist))
                    .album(frame: ID3FrameWithStringContent(content: self.musicSelectedDraft.album))
                    .recordingYear(frame: ID3FrameWithIntegerContent(value: self.musicSelectedDraft.year))
                    .trackPosition(frame: ID3FramePartOfTotal(part: self.musicSelectedDraft.track, total: nil))
                    .genre(frame: .init(genre: nil, description: self.musicSelectedDraft.genre))
                
                if !self.musicLyric.isEmpty {
                    builder = builder.unsynchronisedLyrics(language: .eng,
                                                           frame: ID3FrameWithLocalizedContent(
                                                            language: ID3FrameContentLanguage.eng,
                                                            contentDescription: "Lyric - \(self.musicSelectedDraft.musicTitle)",
                                                            content: self.musicLyric))
                }
                
                if !coverImagePath.isEmpty {
                    let imageURL = URL(fileURLWithPath: coverImagePath.removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? "")
                    
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
                try id3TagEditor.write(tag: id3Tag, to: musicUrl.absoluteString.removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? "")
                
                return true
            } catch {
                print(error)
                return false
            }
        }
        return false
    }

    func saveCover(coverImageUrl: URL) -> Bool {
        let id3TagEditor = ID3TagEditor()
        do {
            if let id3Tag = try id3TagEditor.read(from: self.musicSelected.filePath.removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? "") {
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

