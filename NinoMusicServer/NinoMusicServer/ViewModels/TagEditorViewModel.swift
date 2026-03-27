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

enum CaseKind: String, CaseIterable {
    case lowercase = "lowercase"
    case uppercase = "uppercase"
    case capitalized = "capitalized"
    
    var description: String {
        switch self {
        case .lowercase:
            return "minúsculas"
        case .uppercase:
            return "MAIÚSCULAS"
        case .capitalized:
            return "Primeira Letra Maiúscula"
        }
    }

    static var allDescriptions: [String] {
        allCases.map { $0.description }
    }
}

class TagEditorViewModel: BaseViewModel {
    @Published var musicsLibrary: [Music] = []
    @Published var musicsFileDir: [Music] = []
    @Published var idMusicsSelected: Set<UUID> = []
    @Published var musicSelectedCommonFields: Music = Music.emptyMusic
    @Published var caseKind: CaseKind = .capitalized
    @Published var hasCommonMusicTitle: Bool = false
    @Published var hasCommonArtist: Bool = false
    @Published var hasCommonAlbum: Bool = false
    @Published var hasCommonTrack: Bool = false
    @Published var hasCommonYear: Bool = false
    @Published var hasCommonGenre: Bool = false
    
    var origin: EditOrigin = .fileDir
    
    var genres: [String] = CaseKind.allDescriptions
    
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
    
    func GetCaseKind() -> CaseKind {
        let defaults = UserDefaults.standard
        return CaseKind(rawValue: defaults.string(forKey: "CaseKind") ?? "capitalized") ?? .capitalized
    }
    
    func SetCaseKind(newValue: String) {
        let defaults = UserDefaults.standard
        defaults.set(newValue , forKey: "CaseKind")
    }
    
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
    
    var selectedCount: Int {
        idMusicsSelected.count
    }

    var selectedCountText: String {
        selectedCount == 1 ? "1 música selecionada" : "\(selectedCount) músicas selecionadas"
    }
    
    func setSelection(origin: EditOrigin, selection: Set<Music.ID>) {
        self.origin = origin
        self.idMusicsSelected = selection
        refreshCommonFields()
    }

    func updateMusicTitle(_ value: String) {
        updateSelectedMusic { $0.musicTitle = value }
    }

    func updateArtist(_ value: String) {
        updateSelectedMusic { $0.artist = value }
    }

    func updateAlbum(_ value: String) {
        updateSelectedMusic { $0.album = value }
    }

    func updateYear(_ value: String) {
        updateSelectedMusic { $0.year = value }
    }

    func updateTrack(_ value: Int) {
        updateSelectedMusic { $0.track = value }
    }

    func updateTrackFromField(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let track = Int(trimmed) else {
            return
        }

        updateTrack(track)
    }

    func updateGenre(_ value: String) {
        updateSelectedMusic { $0.genre = value }
    }

    private func updateSelectedMusic(_ update: (inout Music) -> Void) {
        guard !idMusicsSelected.isEmpty else {
            return
        }

        for index in musicsLibrary.indices where idMusicsSelected.contains(musicsLibrary[index].id) {
            var updated = musicsLibrary[index]
            update(&updated)
            musicsLibrary[index] = updated
        }

        refreshCommonFields()
    }

    private func refreshCommonFields() {
        let selectedMusics = self.origin == .library ? musicsLibrary.filter { idMusicsSelected.contains($0.id) } : musicsFileDir.filter { idMusicsSelected.contains($0.id) }
        guard let first = selectedMusics.first else {
            musicSelectedCommonFields = Music.emptyMusic
            hasCommonMusicTitle = false
            hasCommonArtist = false
            hasCommonAlbum = false
            hasCommonTrack = false
            hasCommonYear = false
            hasCommonGenre = false
            return
        }

        hasCommonMusicTitle = selectedMusics.hasCommon(\.musicTitle)
        hasCommonArtist = selectedMusics.hasCommon(\.artist)
        hasCommonAlbum = selectedMusics.hasCommon(\.album)
        hasCommonTrack = selectedMusics.hasCommon(\.track)
        hasCommonYear = selectedMusics.hasCommon(\.year)
        hasCommonGenre = selectedMusics.hasCommon(\.genre)

        musicSelectedCommonFields = Music(
            id: first.id,
            seq: selectedMusics.commonInt(\.seq, fallback: 0),
            idServer: 0,
            artist: selectedMusics.commonString(\.artist),
            album: selectedMusics.commonString(\.album),
            year: selectedMusics.commonString(\.year),
            track: selectedMusics.commonInt(\.track, fallback: 0),
            musicTitle: selectedMusics.commonString(\.musicTitle),
            genre: selectedMusics.commonString(\.genre),
            duration: selectedMusics.commonInt(\.duration, fallback: 0),
            filePath: selectedMusics.commonString(\.filePath),
            hasLyric: false
        )
    }

    var trackFieldText: String {
        hasCommonTrack ? String(musicSelectedCommonFields.track) : ""
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

