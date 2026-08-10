//
//  AlbunsViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 01/04/25.
//

import Foundation

class AlbunsViewModel: BaseViewModel {
    @Published var albuns: [Album] = []
    @Published var idAlbumSelected: Album.ID = UUID()
    @Published var filePathCover: String = String()
    @Published var albumSelected: Album = Album.emptyAlbum
    
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
    
    func goToPreviusAlbum() {
        let searchCount = albumSelected.seq  - 1
        if let selected = self.albuns.first(where: {$0.seq == searchCount}) {
            self.idAlbumSelected = selected.id
            self.albumSelected = selected
            self.filePathCover = albumSelected.musics.first?.filePath ?? ""
        }
    }
    
    func goToNextAlbum() {
        let searchCount = albumSelected.seq  + 1
        if let selected = self.albuns.first(where: {$0.seq == searchCount}) {
            self.idAlbumSelected = selected.id
            self.albumSelected = selected
            self.filePathCover = self.albumSelected.musics.first?.filePath ?? ""
        }
    }
    
    func setIdSelection(selection: UUID) {
        for album in albuns {
            if let item = album.musics.first(where: { $0.id == selection }) {
                self.musicSelected.id = item.id
                self.musicSelected.seq = item.seq
                self.musicSelected.idServer = item.idServer
                self.musicSelected.artist = album.artist
                self.musicSelected.album = album.album
                self.musicSelected.year = album.year
                self.musicSelected.track = item.track
                self.musicSelected.musicTitle = item.musicTitle
                self.musicSelected.genre = album.genre
                self.musicSelected.duration = item.duration
                self.musicSelected.filePath = item.filePath
                self.musicSelected.hasLyric = item.hasLyric
                return
            }
        }

        self.musicSelected = Music.emptyMusic
    }
    
    func reloadAlbuns() async {
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

        let albumList = await withCheckedContinuation { (continuation: CheckedContinuation<[Album], Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                var albumList = [Album]()
                var seqAlbum = 0

                var currentAlbumId: Int?
                var currentAlbumName = String()
                var currentArtist = String()
                var currentYear = Int()
                var currentGenre = String()
                var currentMusics = [AlbumMusic]()

                func appendCurrentAlbumIfNeeded() {
                    guard currentAlbumId != nil else {
                        return
                    }

                    seqAlbum += 1
                    albumList.append(Album(seq: seqAlbum,
                                           album: currentAlbumName,
                                           artist: currentArtist,
                                           year: currentYear,
                                           genre: currentGenre,
                                           musics: currentMusics))
                }

                do {
                    if let rowsAlbuns = try self.helper?.sql(query: sqlAlbuns) {
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
                                    appendCurrentAlbumIfNeeded()
                                    currentAlbumId = idAlbum
                                    currentAlbumName = album
                                    currentArtist = artist
                                    currentYear = year
                                    currentGenre = genre
                                    currentMusics.removeAll(keepingCapacity: true)
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

                        appendCurrentAlbumIfNeeded()
                    }
                } catch {
                    print(error)
                }

                continuation.resume(returning: albumList)
            }
        }

        await MainActor.run {
            self.albuns = albumList

            if let firstAlbum = albumList.first {
                self.idAlbumSelected = firstAlbum.id
                self.albumSelected = firstAlbum
                self.filePathCover = firstAlbum.musics.first?.filePath ?? ""

                if let firstMusic = firstAlbum.musics.first {
                    self.idMusicSelected = firstMusic.id
                    self.setIdSelection(selection: firstMusic.id)
                } else {
                    self.idMusicSelected = nil
                    self.musicSelected = Music.emptyMusic
                }
            } else {
                self.idAlbumSelected = UUID()
                self.albumSelected = Album.emptyAlbum
                self.filePathCover = ""
                self.idMusicSelected = nil
                self.musicSelected = Music.emptyMusic
            }

            self.isLoading = false
        }
    }
}

