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
    
    override func onNavigate(kind: NavigationKind, originNotification: MusicContentViewType?) {
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
    
    func setIdSelection(selection: Music.ID) {
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
            }
        }
    }
    
    func reloadAlbuns() {
        let sqlAlbuns = """
            SELECT DISTINCT
               \(DBConstants.TableMusic.colIdAlbum),
               \(DBConstants.TableAlbum.colAlbum),
               \(DBConstants.TableArtist.colArtist),
               \(DBConstants.TableAlbum.colYear),
               \(DBConstants.TableGenre.colGenre)
            FROM
               \(DBConstants.TableMusic.tableName)
               INNER JOIN \(DBConstants.TableArtist.tableName) ON \(DBConstants.TableArtist.tableName).\(DBConstants.TableArtist.colRowId) = \(DBConstants.TableMusic.colIdArtist)
               INNER JOIN \(DBConstants.TableAlbum.tableName) ON \(DBConstants.TableAlbum.tableName).\(DBConstants.TableAlbum.colRowId) = \(DBConstants.TableMusic.colIdAlbum)
               INNER JOIN \(DBConstants.TableGenre.tableName) ON \(DBConstants.TableGenre.tableName).\(DBConstants.TableGenre.colRowId) = \(DBConstants.TableMusic.colIdGenre)
            ORDER BY
               \(DBConstants.TableAlbum.colAlbum),
               \(DBConstants.TableArtist.colArtist),
               \(DBConstants.TableAlbum.colYear),
               \(DBConstants.TableMusic.colTrack)
            """
        var albumList = [Album]()
        var musicList = [AlbumMusic]()
        var seqAlbum = 0
        do {
            if let rowsAlbuns = try self.helper?.executeQuery(query: sqlAlbuns) {
                for rowAlbum in rowsAlbuns {
                    if
                        let idAlbum = rowAlbum[DBConstants.TableMusic.colIdAlbum] as? Int,
                        let album = rowAlbum[DBConstants.TableAlbum.colAlbum] as? String,
                        let artist = rowAlbum[DBConstants.TableArtist.colArtist] as? String,
                        let year = rowAlbum[DBConstants.TableAlbum.colYear] as? String,
                        let genre = rowAlbum[DBConstants.TableGenre.colGenre] as? String
                    {
                        let sqlMusics = """
                        SELECT
                           \(DBConstants.TableMusic.colRowId),
                           \(DBConstants.TableMusic.colTrack),
                           \(DBConstants.TableMusic.colTitle),
                           \(DBConstants.TableMusic.colDuration),
                           \(DBConstants.TableMusic.colFilePath)
                        FROM
                           \(DBConstants.TableMusic.tableName)
                        WHERE
                           \(DBConstants.TableMusic.colIdAlbum) = \(idAlbum) 
                        ORDER BY
                           \(DBConstants.TableMusic.colTrack),
                           \(DBConstants.TableMusic.colTitle)
                        """
                        do {
                            if let rowsMusicsAlbum = try self.helper?.executeQuery(query: sqlMusics) {
                                var seqMusic = 0
                                for rowMusicAlbum in rowsMusicsAlbum {
                                    if  let idServer = rowMusicAlbum[DBConstants.TableMusic.colRowId] as? Int,
                                        let track = rowMusicAlbum[DBConstants.TableMusic.colTrack] as? Int,
                                        let musicTitle = rowMusicAlbum[DBConstants.TableMusic.colTitle] as? String,
                                        let duration = rowMusicAlbum[DBConstants.TableMusic.colDuration] as? Int,
                                        let filePath = rowMusicAlbum[DBConstants.TableMusic.colFilePath] as? String
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
    }
}

