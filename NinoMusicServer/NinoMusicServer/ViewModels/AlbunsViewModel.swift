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
    @Published var idAlbumSelected: Album.ID = UUID()
    @Published var filePathCover: String = String()
    @Published var albumSelected: Album = Album.emptyAlbum
    @Published var indexAlbumSelected: Int = 0 {
        didSet {
            if indexAlbumSelected >= 0 && indexAlbumSelected < self.albuns.count {
                let selected = self.albuns[indexAlbumSelected]
                self.idAlbumSelected = selected.id
                self.albumSelected = selected
                self.filePathCover = self.albumSelected.musics.first?.filePath ?? ""
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
            }
        }
    }
    
    func reloadAlbuns() {
        let sqlAlbuns = """
               SELECT DISTINCT
                  \(DbConstants.TableMusic.colIdAlbum),
                  \(DbConstants.TableAlbum.colAlbum),
                  \(DbConstants.TableArtist.colArtist),
                  \(DbConstants.TableAlbum.colYear),
                  \(DbConstants.TableGenre.colGenre)
               FROM
                  \(DbConstants.TableMusic.tableName)
                  INNER JOIN \(DbConstants.TableArtist.tableName) ON \(DbConstants.TableArtist.tableName).\(DbConstants.TableArtist.colRowId) = \(DbConstants.TableMusic.colIdArtist)
                  INNER JOIN \(DbConstants.TableAlbum.tableName) ON \(DbConstants.TableAlbum.tableName).\(DbConstants.TableAlbum.colRowId) = \(DbConstants.TableMusic.colIdAlbum)
                  INNER JOIN \(DbConstants.TableGenre.tableName) ON \(DbConstants.TableGenre.tableName).\(DbConstants.TableGenre.colRowId) = \(DbConstants.TableMusic.colIdGenre)
               ORDER BY
                  \(DbConstants.TableAlbum.colAlbum),
                  \(DbConstants.TableArtist.colArtist),
                  \(DbConstants.TableAlbum.colYear),
                  \(DbConstants.TableMusic.colTrack)
               """
        var albumList = [Album]()
        var musicList = [AlbumMusic]()
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
                              \(DbConstants.TableMusic.colFilePath)
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
                                        let filePath = rowMusicAlbum[DbConstants.TableMusic.colFilePath] as? String
                                    {
                                        seqMusic += 1
                                        musicList.append(AlbumMusic(seq: seqMusic,
                                                                    idServer: idServer,
                                                                    track: track,
                                                                    musicTitle: musicTitle,
                                                                    duration: duration,
                                                                    filePath: filePath))
                                    }
                                }
                                seqMusic = 0
                                seqAlbum += 1
                                albumList.append(Album(seq: seqAlbum,
                                                       album: album,
                                                       artist: artist,
                                                       year: year,
                                                       genre: genre,
                                                       musics: musicList))
                                
                                
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
        self.albuns = albumList
        
        self.covers.removeAll()
        for album in self.albuns {
            let id = album.id
            var image = NSImage()
            if let pathCover = album.musics.first?.filePath {
                image = Id3TagUtils.getImageCover(path: pathCover) ?? NSImage()
            }
            self.covers.append(AlbumCover(id: id,
                                          cover: Image(nsImage: image)))
        }
    }
}

