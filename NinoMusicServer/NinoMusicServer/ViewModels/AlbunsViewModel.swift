//
//  AlbunsViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 01/04/25.
//

import Foundation
import OSLog
import SwiftUI

class AlbunsViewModel: BaseViewModel {
    private static let signposter = OSSignposter(subsystem: "nino.musicserver", category: "AlbunsViewModel")
    private let initialCoverBatchSize = 12
    private let coverPrefetchRadius = 10

    @Published var albuns: [Album] = []
    @Published var covers: [AlbumCover] = []
    @Published var indexAlbumSelected: Int = 0

    private var coverPathByAlbumId: [UUID: String] = [:]
    private var loadedCoverIds = Set<UUID>()
    private var loadingCoverIds = Set<UUID>()

    var idAlbumSelected: UUID? {
        selectedAlbum?.id
    }

    var albumSelected: Album {
        selectedAlbum ?? Album.emptyAlbum
    }

    private var selectedAlbum: Album? {
        guard indexAlbumSelected >= 0, indexAlbumSelected < albuns.count else {
            return nil
        }
        return albuns[indexAlbumSelected]
    }

    func loadVisibleCovers(around index: Int) {
        Task {
            await loadCovers(around: index, limit: max(initialCoverBatchSize, coverPrefetchRadius * 2 + 1))
        }
    }

    private func loadInitialCovers() {
        loadVisibleCovers(around: 0)
    }

    @MainActor
    private func loadCovers(around index: Int, limit: Int) async {
        guard !covers.isEmpty else {
            return
        }

        let safeIndex = min(max(index, 0), covers.count - 1)
        let lowerBound = max(0, safeIndex - coverPrefetchRadius)
        let upperBound = min(covers.count - 1, safeIndex + coverPrefetchRadius)

        var idsToLoad: [UUID] = []
        for idx in lowerBound...upperBound {
            let id = covers[idx].id
            if !loadedCoverIds.contains(id), !loadingCoverIds.contains(id) {
                idsToLoad.append(id)
            }
        }

        if idsToLoad.count < limit {
            for cover in covers where idsToLoad.count < limit {
                if !loadedCoverIds.contains(cover.id), !loadingCoverIds.contains(cover.id) {
                    idsToLoad.append(cover.id)
                }
            }
        }

        guard !idsToLoad.isEmpty else {
            return
        }

        for id in idsToLoad {
            loadingCoverIds.insert(id)
        }

        let coverPaths = idsToLoad.compactMap { id -> (UUID, String)? in
            guard let path = coverPathByAlbumId[id], !path.isEmpty else {
                loadedCoverIds.insert(id)
                return nil
            }
            return (id, path)
        }

        let loadedItems: [(UUID, Image)] = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var items: [(UUID, Image)] = []
                for (id, path) in coverPaths {
                    if let image = Id3TagUtils.getImageCover(path: path, maxPixelSize: 320) {
                        items.append((id, Image(nsImage: image)))
                    }
                }
                continuation.resume(returning: items)
            }
        }

        var imageById: [UUID: Image] = [:]
        for (id, image) in loadedItems {
            imageById[id] = image
        }

        for idx in covers.indices {
            let id = covers[idx].id
            if let image = imageById[id] {
                covers[idx].cover = image
                loadedCoverIds.insert(id)
            }
        }

        for id in idsToLoad {
            loadingCoverIds.remove(id)
        }
    }
    
    override func onNavigateMusics(kind: NavigationKind, originNotification: MusicContentViewType?) {
        if originNotification == .albuns {
            let searchCount = kind == .next ? musicSelected.seq + 1 : musicSelected.seq - 1
            if let selected = self.albumSelected.musics.first(where: {$0.seq == searchCount}) {
                self.idMusicSelected = selected.id
                self.setIdSelection(selection: self.idMusicSelected ?? UUID())
                musicPlayerViewModel.setMusicSelected(music: self.musicSelected)
                musicPlayerViewModel.originCurrentMusic = .albuns
            }
        }
    }
    
    func setIdSelection(selection: UUID) {
        for album in albuns {
            if let item = album.musics.first(where: { $0.id == selection }) {
                self.musicSelected.id = item.id
                self.musicSelected.seq = item.seq
                self.musicSelected.artist = album.artist
                self.musicSelected.album = album.album
                self.musicSelected.year = album.year
                self.musicSelected.track = item.track
                self.musicSelected.musicTitle = item.musicTitle
                self.musicSelected.genre = album.genre
                self.musicSelected.duration = item.duration
                self.musicSelected.filePath = item.filePath
                self.musicSelected.hasLyric = item.hasLyric
            }
        }
    }
    
    func reloadAlbuns() async {
        let reloadState = Self.signposter.beginInterval("reloadAlbuns")
        defer {
            Self.signposter.endInterval("reloadAlbuns", reloadState)
        }

          let sqlAlbuns = """
                    SELECT
                        \(DbConstants.TableMusic.colIdAlbum),
                        \(DbConstants.TableAlbum.colAlbum),
                        \(DbConstants.TableArtist.colArtist),
                        \(DbConstants.TableAlbum.colYear),
                        \(DbConstants.TableGenre.colGenre),
                        \(DbConstants.TableMusic.colMusicId),
                        \(DbConstants.TableMusic.colTrack),
                        \(DbConstants.TableMusic.colTitle),
                        \(DbConstants.TableMusic.colDuration),
                        \(DbConstants.TableMusic.colFilePath),
                        \(DbConstants.TableMusic.colHasLyrics)
                    FROM
                        \(DbConstants.TableMusic.tableName)
                        INNER JOIN \(DbConstants.TableArtist.tableName) ON \(DbConstants.TableArtist.tableName).\(DbConstants.TableArtist.colArtistId) = \(DbConstants.TableMusic.colIdArtist)
                        INNER JOIN \(DbConstants.TableAlbum.tableName) ON \(DbConstants.TableAlbum.tableName).\(DbConstants.TableAlbum.colAlbumId) = \(DbConstants.TableMusic.colIdAlbum)
                        INNER JOIN \(DbConstants.TableGenre.tableName) ON \(DbConstants.TableGenre.tableName).\(DbConstants.TableGenre.colGenreId) = \(DbConstants.TableMusic.colIdGenre)
                    ORDER BY
                        \(DbConstants.TableAlbum.colAlbum),
                        \(DbConstants.TableArtist.colArtist),
                        \(DbConstants.TableAlbum.colYear),
                        \(DbConstants.TableMusic.colTrack),
                        \(DbConstants.TableMusic.colTitle)
                    """
        await MainActor.run {
            self.isLoading = true
        }

        let result = await withCheckedContinuation { (continuation: CheckedContinuation<([Album], [AlbumCover], [UUID: String]), Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                var albumList = [Album]()
                var coversList = [AlbumCover]()
                var coverPathListById: [UUID: String] = [:]
                var seqAlbum = 0

                var currentAlbumId: Int?
                var currentAlbumName = String()
                var currentArtist = String()
                var currentYear = Int()
                var currentGenre = String()
                var currentMusics = [AlbumMusic]()
                var currentCoverPath = String()

                func appendCurrentAlbum() {
                    guard currentAlbumId != nil else {
                        return
                    }

                    seqAlbum += 1
                    let album = Album(seq: seqAlbum,
                                      album: currentAlbumName,
                                      artist: currentArtist,
                                      year: currentYear,
                                      genre: currentGenre,
                                      musics: currentMusics)
                    albumList.append(album)
                    coverPathListById[album.id] = currentCoverPath
                    coversList.append(AlbumCover(id: album.id,
                                                 coverURL: currentCoverPath,
                                                 cover: nil))
                }

                do {
                    let fetchState = Self.signposter.beginInterval("reloadAlbuns.fetchRows")
                    let rowsAlbuns = try self.helper?.sql(query: sqlAlbuns)
                    Self.signposter.endInterval("reloadAlbuns.fetchRows", fetchState)

                    if let rowsAlbuns {
                        let buildState = Self.signposter.beginInterval("reloadAlbuns.buildAlbums")
                        defer {
                            Self.signposter.endInterval("reloadAlbuns.buildAlbums", buildState)
                        }

                        for rowAlbum in rowsAlbuns {
                            if
                                let idAlbum = rowAlbum[DbConstants.TableMusic.colIdAlbum] as? Int,
                                let album = rowAlbum[DbConstants.TableAlbum.colAlbum] as? String,
                                let artist = rowAlbum[DbConstants.TableArtist.colArtist] as? String,
                                let year = rowAlbum[DbConstants.TableAlbum.colYear] as? Int,
                                let genre = rowAlbum[DbConstants.TableGenre.colGenre] as? String,
                                let idServer = rowAlbum[DbConstants.TableMusic.colMusicId] as? Int,
                                let track = rowAlbum[DbConstants.TableMusic.colTrack] as? Int,
                                let musicTitle = rowAlbum[DbConstants.TableMusic.colTitle] as? String,
                                let duration = rowAlbum[DbConstants.TableMusic.colDuration] as? Int,
                                let filePath = rowAlbum[DbConstants.TableMusic.colFilePath] as? String,
                                let hasLyric = rowAlbum[DbConstants.TableMusic.colHasLyrics] as? Int
                            {
                                if currentAlbumId != idAlbum {
                                    appendCurrentAlbum()

                                    currentAlbumId = idAlbum
                                    currentAlbumName = album
                                    currentArtist = artist
                                    currentYear = year
                                    currentGenre = genre
                                    currentMusics.removeAll(keepingCapacity: true)
                                    currentCoverPath = filePath
                                }

                                currentMusics.append(AlbumMusic(seq: currentMusics.count + 1,
                                                                idServer: idServer,
                                                                track: track,
                                                                musicTitle: musicTitle,
                                                                duration: duration,
                                                                filePath: filePath,
                                                                hasLyric: hasLyric == 1))
                            }
                        }

                        appendCurrentAlbum()
                    }
                } catch {
                    print(error)
                }

                continuation.resume(returning: (albumList, coversList, coverPathListById))
            }
        }

        await MainActor.run {
            self.albuns = result.0
            self.covers = result.1
            self.coverPathByAlbumId = result.2
            self.loadedCoverIds.removeAll(keepingCapacity: true)
            self.loadingCoverIds.removeAll(keepingCapacity: true)
            if self.indexAlbumSelected >= self.albuns.count {
                self.indexAlbumSelected = max(self.albuns.count - 1, 0)
            }
            self.isLoading = false
        }

        await MainActor.run {
            self.loadInitialCovers()
        }
    }
}

