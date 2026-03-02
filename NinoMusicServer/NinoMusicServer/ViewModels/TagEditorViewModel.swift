//
//  TagEditorViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Baptista Machado on 06/02/26.
//

import SwiftUI
import ID3TagEditor

class TagEditorViewModel: BaseViewModel {
    @Published var musicsLibrary: [Music] = []
    @Published var musicsFileDir: [Music] = []
    
    func reloadMusics() async {
        let sql = """
            SELECT
               \(DbConstants.TableMusic.tableName).\(DbConstants.TableMusic.colRowId),
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
               INNER JOIN \(DbConstants.TableArtist.tableName) ON \(DbConstants.TableArtist.tableName).\(DbConstants.TableArtist.colRowId) = \(DbConstants.TableMusic.colIdArtist)
               INNER JOIN \(DbConstants.TableAlbum.tableName) ON \(DbConstants.TableAlbum.tableName).\(DbConstants.TableAlbum.colRowId) = \(DbConstants.TableMusic.colIdAlbum)
               INNER JOIN \(DbConstants.TableGenre.tableName) ON \(DbConstants.TableGenre.tableName).\(DbConstants.TableGenre.colRowId) = \(DbConstants.TableMusic.colIdGenre)
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
                                let idServer = row[DbConstants.TableMusic.colRowId] as? Int,
                                let artist = row[DbConstants.TableArtist.colArtist] as? String,
                                let album = row[DbConstants.TableAlbum.colAlbum] as? String,
                                let year = row[DbConstants.TableAlbum.colYear] as? String,
                                let track = row[DbConstants.TableMusic.colTrack] as? Int,
                                let musicTitle = row[DbConstants.TableMusic.colTitle] as? String,
                                let genre = row[DbConstants.TableGenre.colGenre] as? String,
                                let duration = row[DbConstants.TableMusic.colRowId] as? Int,
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
        } else {
            self.musicSelected = Music.emptyMusic
        }
    }
    
    func setIdFilesSelection(selection: Music.ID) {
        self.idMusicSelected = selection
        if let item = self.musicsFileDir.first(where: { $0.id == self.idMusicSelected }) {
            self.idMusicSelected = item.id
            self.musicSelected = item
            self.fileSelected = String((item.filePath as NSString).lastPathComponent).removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? ""
        } else {
            self.musicSelected = Music.emptyMusic
        }
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
            let year = String(((id3Tag?.frames[.recordingYear] as? ID3FrameWithIntegerContent)?.value ?? Int()) as Int)
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
}

enum CaseKind: String {
    case lowercase = "lowercase"
    case uppercase = "uppercase"
    case capitalized = "capitalized"
    
    var description: String {
        switch self {
        case .lowercase:
            return "minúculas"
        case .uppercase:
            return "MAIÚSCULAS"
        case .capitalized:
            return "Primeira Letra Maiúscula"
        }
    }
}

class TagEditorConfigViewModel: ObservableObject {
    
    @Published var caseKind: CaseKind = .capitalized
    @Published var genres: [String] = []

    func saveTagEditorConfig() {
        let defaults = UserDefaults.standard
        defaults.set(caseKind.rawValue , forKey: "CaseKind")
        defaults.set(genres, forKey: "Genres")
    }
    
    func loadTagEditorConfig() {
        let defaults = UserDefaults.standard
        self.caseKind = CaseKind(rawValue: defaults.string(forKey: "CaseKind") ?? "capitalized") ?? .capitalized
        self.genres = defaults.stringArray(forKey: "Genres") ?? []
    }
    
    func addGenre(_ genre: String) {
        genres.append(genre)
    }
    
    func removeGenre(_ genre: String) {
        genres.removeAll { $0 == genre }
    }
    
    func getGenres() -> [String] {
        return self.genres
    }
}
