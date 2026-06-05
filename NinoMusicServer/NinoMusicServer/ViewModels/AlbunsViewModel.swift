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

    @Published var albuns: [Album] = []
    @Published var covers: [AlbumCover] = []
    @Published var indexAlbumSelected: Int = 0

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

        let result = await withCheckedContinuation { (continuation: CheckedContinuation<([Album], [AlbumCover]), Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                var albumList = [Album]()
                var coversList = [AlbumCover]()
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

                    let image = Id3TagUtils.getImageCover(path: currentCoverPath, maxPixelSize: 320) ?? NSImage()
                    coversList.append(AlbumCover(id: album.id,
                                                 coverURL: currentCoverPath,
                                                 cover: Image(nsImage: image)))
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

                continuation.resume(returning: (albumList, coversList))
            }
        }

        await MainActor.run {
            self.albuns = result.0
            self.covers = result.1
            if self.indexAlbumSelected >= self.albuns.count {
                self.indexAlbumSelected = max(self.albuns.count - 1, 0)
            }
            self.isLoading = false
        }
    }
}

