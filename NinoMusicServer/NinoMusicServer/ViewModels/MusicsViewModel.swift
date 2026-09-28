//
//  MusicsViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 12/03/25.
//

import SwiftUI
import SQLite3

class MusicsViewModel: BaseViewModel {
    @Published var musics: [Music] = []
    
    override init(musicPlayerViewModel: MusicPlayerViewModel) {
        super.init(musicPlayerViewModel: musicPlayerViewModel)
        NotificationCenter.default.addObserver(forName: Notification.Name("musicExecuted"),
                                               object: nil,
                                               queue: .main) { [weak self] notification in
            guard let self = self,
                  let idServer = notification.userInfo?["idServer"] as? Int,
                  let lastExecution = notification.userInfo?["lastExecution"] as? Date,
                  let countExecution = notification.userInfo?["countExecution"] as? Int else { return }
            self.updateExecution(idServer: idServer, lastExecution: lastExecution, countExecution: countExecution)
        }
        NotificationCenter.default.addObserver(forName: Notification.Name("musicFavoriteChanged"),
                                               object: nil,
                                               queue: .main) { [weak self] notification in
            guard let self = self,
                  let idServer = notification.userInfo?["idServer"] as? Int,
                  let isFavorite = notification.userInfo?["isFavorite"] as? Bool else { return }
            self.updateFavorite(idServer: idServer, isFavorite: isFavorite)
        }
    }
    
    private func updateFavorite(idServer: Int, isFavorite: Bool) {
        if let index = self.musics.firstIndex(where: { $0.idServer == idServer }) {
            self.musics[index].isFavorite = isFavorite
        }
        if self.musicSelected.idServer == idServer {
            self.musicSelected.isFavorite = isFavorite
        }
    }
    
    private func updateExecution(idServer: Int, lastExecution: Date, countExecution: Int) {
        if let index = self.musics.firstIndex(where: { $0.idServer == idServer }) {
            self.musics[index].lastExecution = lastExecution
            self.musics[index].countExecution = countExecution
        }
        if self.musicSelected.idServer == idServer {
            self.musicSelected.lastExecution = lastExecution
            self.musicSelected.countExecution = countExecution
        }
    }
    
    override func onNavigateMusics(kind: NavigationKind, originNotification: MusicContentViewType?) {
        if originNotification == .musics {
            let searchCount = kind == .next ? musicSelected.seq + 1 : musicSelected.seq - 1
            if let selected = self.musics.first(where: {$0.seq == searchCount}) {
                self.idMusicSelected = selected.id
                self.musicSelected = selected
                musicPlayerViewModel.setMusicSelected(music: selected)
                musicPlayerViewModel.originCurrentMusic = .musics
            }
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
               \(DbConstants.TableMusic.colHasLyrics),
               \(DbConstants.TableMusic.colIsFavorite),
               \(DbConstants.TableMusic.colLastUpdate),
               \(DbConstants.TableMusic.colLastExecution),
               \(DbConstants.TableMusic.colCountExecution)
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
                                let hasLyric = row[DbConstants.TableMusic.colHasLyrics] as? Int,
                                let isFavorite = row[DbConstants.TableMusic.colIsFavorite] as? Int,
                                let lastUpdate = row[DbConstants.TableMusic.colLastUpdate] as? Int,
                                let lastExecution = row[DbConstants.TableMusic.colLastExecution] as? Int,
                                let countExecution = row[DbConstants.TableMusic.colCountExecution] as? Int
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
                                                       hasLyric: hasLyric == 1,
                                                       isFavorite: isFavorite == 1,
                                                       lastUpdate: Date(timeIntervalSince1970: TimeInterval(lastUpdate)),
                                                       lastExecution: Date(timeIntervalSince1970: TimeInterval(lastExecution)),
                                                       countExecution: countExecution)
                                                 )
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
            self.musics = musicList
            self.isLoading = false
        }
    }
    
    func toggleFavorite(music: Music) {
        saveFavorite(idServer: music.idServer, isFavorite: !music.isFavorite)
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
    
    func filteredMusics(searchTerm: String) -> [Music] {
        guard !searchTerm.isEmpty else { return self.musics }
        return self.musics.filter {
            $0.musicTitle.localizedCaseInsensitiveContains(searchTerm) ||
            $0.artist.localizedCaseInsensitiveContains(searchTerm) ||
            $0.album.localizedCaseInsensitiveContains(searchTerm)
        }
    }
    
    func availableLetters(in musics: [Music]) -> [String] {
        var letters = [String]()
        for music in musics {
            let letter = String(music.musicTitle.first ?? " ").uppercased()
            if letters.last != letter {
                letters.append(letter)
            }
        }
        return letters
    }
    
    func firstMusicId(forLetter letter: String, in musics: [Music]) -> Music.ID? {
        musics.first(where: { String($0.musicTitle.first ?? " ").uppercased() == letter })?.id
    }
    
}
