//
//  AlbunsViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 01/04/25.
//

import Foundation
import SwiftUI

class AlbunsViewModel: BaseViewModel {
    @Published var albuns: [Album] = []
    @Published var covers: [AlbumCover] = []
    @Published var idAlbumSelected: UUID? = UUID()
    @Published var albumSelected: Album = Album.emptyAlbum
    @Published var indexAlbumSelected: Int = 0 {
        didSet {
            if indexAlbumSelected >= 0 && indexAlbumSelected < self.albuns.count {
                let selected = self.albuns[indexAlbumSelected]
                self.idAlbumSelected = selected.id
                self.albumSelected = selected
            }
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
        let sqlAlbuns = """
               SELECT DISTINCT
                  \(DbConstants.TableMusic.colIdAlbum),
                  \(DbConstants.TableAlbum.colAlbum),
                  \(DbConstants.TableArtist.colArtist),
                  \(DbConstants.TableAlbum.colYear),
                  \(DbConstants.TableGenre.colGenre)
               FROM
                  \(DbConstants.TableMusic.tableName)
                  INNER JOIN \(DbConstants.TableArtist.tableName) ON \(DbConstants.TableArtist.tableName).\(DbConstants.TableArtist.colArtistId) = \(DbConstants.TableMusic.colIdArtist)
                  INNER JOIN \(DbConstants.TableAlbum.tableName) ON \(DbConstants.TableAlbum.tableName).\(DbConstants.TableAlbum.colAlbumId) = \(DbConstants.TableMusic.colIdAlbum)
                  INNER JOIN \(DbConstants.TableGenre.tableName) ON \(DbConstants.TableGenre.tableName).\(DbConstants.TableGenre.colGenreId) = \(DbConstants.TableMusic.colIdGenre)
               ORDER BY
                  \(DbConstants.TableAlbum.colAlbum),
                  \(DbConstants.TableArtist.colArtist),
                  \(DbConstants.TableAlbum.colYear),
                  \(DbConstants.TableMusic.colTrack)
               """
        await MainActor.run {
            self.isLoading = true
        }

        let result = await withCheckedContinuation { (continuation: CheckedContinuation<([Album], [AlbumCover]), Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                var albumList = [Album]()
                var musicList = [AlbumMusic]()
                var coversList = [AlbumCover]()
                var seqAlbum = 0
                do {
                    if let rowsAlbuns = try self.helper?.sql(query: sqlAlbuns) {
                        for rowAlbum in rowsAlbuns {
                            if
                                let idAlbum = rowAlbum[DbConstants.TableMusic.colIdAlbum] as? Int,
                                let album = rowAlbum[DbConstants.TableAlbum.colAlbum] as? String,
                                let artist = rowAlbum[DbConstants.TableArtist.colArtist] as? String,
                                let year = rowAlbum[DbConstants.TableAlbum.colYear] as? String,
                                let genre = rowAlbum[DbConstants.TableGenre.colGenre] as? String
                            {
                                let sqlMusics = """
                                   SELECT
                                      \(DbConstants.TableMusic.colRowId),
                                      \(DbConstants.TableMusic.colTrack),
                                      \(DbConstants.TableMusic.colTitle),
                                      \(DbConstants.TableMusic.colDuration),
                                      \(DbConstants.TableMusic.colFilePath),
                                      \(DbConstants.TableMusic.colHasLyrics)
                                   FROM
                                      \(DbConstants.TableMusic.tableName)
                                   WHERE
                                      \(DbConstants.TableMusic.colIdAlbum) = \(idAlbum) 
                                   ORDER BY
                                      \(DbConstants.TableMusic.colTrack),
                                      \(DbConstants.TableMusic.colTitle)
                                   """
                                do {
                                    if let rowsMusicsAlbum = try self.helper?.sql(query: sqlMusics) {
                                        var seqMusic = 0
                                        for rowMusicAlbum in rowsMusicsAlbum {
                                            if  let idServer = rowMusicAlbum[DbConstants.TableMusic.colRowId] as? Int,
                                                let track = rowMusicAlbum[DbConstants.TableMusic.colTrack] as? Int,
                                                let musicTitle = rowMusicAlbum[DbConstants.TableMusic.colTitle] as? String,
                                                let duration = rowMusicAlbum[DbConstants.TableMusic.colDuration] as? Int,
                                                let filePath = rowMusicAlbum[DbConstants.TableMusic.colFilePath] as? String,
                                                let hasLyric = rowMusicAlbum[DbConstants.TableMusic.colHasLyrics] as? Int
                                            {
                                                seqMusic += 1
                                                musicList.append(AlbumMusic(seq: seqMusic,
                                                                            idServer: idServer,
                                                                            track: track,
                                                                            musicTitle: musicTitle,
                                                                            duration: duration,
                                                                            filePath: filePath,
                                                                            hasLyric: hasLyric == 1))
                                            }
                                        }
                                        seqMusic = 0
                                        seqAlbum += 1
                                        let album = Album(seq: seqAlbum,
                                                          album: album,
                                                          artist: artist,
                                                          year: year,
                                                          genre: genre,
                                                          musics: musicList)
                                        albumList.append(album)
                                        
                                        var image = NSImage()
                                        if let pathCover = musicList.first?.filePath {
                                            image = Id3TagUtils.getImageCover(path: pathCover) ?? NSImage()
                                        }
                                        coversList.append(AlbumCover(id: album.id,
                                                                     coverURL: musicList.first?.filePath ?? "",
                                                                     cover: Image(nsImage: image)))
                                        musicList.removeAll()
                                    }
                                } catch {
                                    print(error)
                                }
                            }
                        }
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
            self.isLoading = false
        }
    }
}

