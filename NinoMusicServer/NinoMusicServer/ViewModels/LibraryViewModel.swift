//
//  LibraryViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 14/03/25.
//

import AVFoundation
import Foundation
import ID3TagEditor
import SwiftData

class LibraryViewModel: ObservableObject, MusicFilesDelegate {
    
    @Published var totalMusics: Int = 0
    @Published var totalTime: TimeInterval = 0
    @Published var isLoading: Bool = false
    
    @Published var directories = [MusicDirectory]()
    
    private var musicFiles: MusicFiles
    
    init(modelContext: ModelContext) {
        self.musicFiles = MusicFiles(modelContext: modelContext)
        self.musicFiles.delegate = self
        self.directories = self.musicFiles.directories
        self.totalMusics = self.directories.reduce(0) { $0 + $1.musicCount }
        self.totalTime = self.directories.reduce(0.0) { $0 + $1.totalTime }
    }
     
    func addDirectory(dirPath: String) async {
        self.isLoading = true
        await self.musicFiles.addDirectory(dirPath: dirPath.removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? "")
        self.directories = self.musicFiles.directories
        self.totalMusics = self.directories.reduce(0) { $0 + $1.musicCount }
        self.totalTime = self.directories.reduce(0.0) { $0 + $1.totalTime }
        self.isLoading = false
    }
    
    func deleteDirectory(selection: UUID) async {
        self.isLoading = true
        if let dir = musicFiles.directories.first(where: { $0.id == selection }) {
            await self.musicFiles.deleteDirectory(dirName: dir.name)
            self.directories = self.musicFiles.directories
            self.totalMusics = self.directories.reduce(0) { $0 + $1.musicCount }
            self.totalTime = self.directories.reduce(0.0) { $0 + $1.totalTime }
            self.isLoading = false
        } else {
            self.isLoading = false
        }

    }
}

extension LibraryViewModel {
    
    func musicLoading(musicsLoaded: Int, totalTime: TimeInterval) {
        self.totalMusics = musicsLoaded
        self.totalTime = totalTime
    }
}

protocol MusicFilesDelegate {
    func musicLoading(musicsLoaded: Int, totalTime: TimeInterval)
}

class MusicFiles {
    private let modelContext: ModelContext
    private var count = 0
    
    var delegate: MusicFilesDelegate?
    var directories = [MusicDirectory]()
    var totalTime: TimeInterval = 0
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        print("Usando SwiftData para gerenciar biblioteca de músicas")
        self.directories = getDirectories()
    }
    
    func addDirectory(dirPath: String) async {
        if addDirectory(dirPath: dirPath) {
            if updateDirectoryNames() {
                self.directories = getDirectories()
                await updateMusicsDatabase { _ in
                    self.saveServerInfo()
                }
            }
        }
    }
    
    func deleteDirectory(dirName: String) async {
        if deleteDirectory(dirName: dirName) {
            if updateDirectoryNames() {
                self.directories = getDirectories()
                await updateMusicsDatabase { _ in
                    self.saveServerInfo()
                }
            }
        }
    }
    
    private func updateMusicsDatabase(completion: @escaping (Int?) -> ()) async {
        cleanMusicsTables()
        for dir in self.directories {
            var countDir = 0
            var totalTimeDir = 0.0
            let url = URL(fileURLWithPath: dir.path)
            var directories = [URL]()
            directories.append(url)
            if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
                for case let dirURL as URL in enumerator {
                    do {
                        let dirAttributes = try dirURL.resourceValues(forKeys:[.isDirectoryKey])
                        if dirAttributes.isDirectory! {
                            directories.append(dirURL)
                        }
                    } catch { print(error, dirURL) }
                }
                let id3TagEditor: ID3TagEditor = ID3TagEditor()
                
                for urlDir in directories {
                    if let enumFiles = FileManager.default.enumerator(at: urlDir, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
                        for case let fileURL as URL in enumFiles {
                            if fileURL.pathExtension.uppercased() == "MP3" {
                                if !musicExists(filePath: fileURL.absoluteString) {
                                    do {
                                        let id3Tag = try id3TagEditor.read(from: fileURL.path)
                                        
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

                                        if addMusic(filePath: filePath,
                                                    musicTitle: musicTitle,
                                                    artist: artist,
                                                    album: album,
                                                    year: year,
                                                    track: track,
                                                    duration: duration,
                                                    genre: genre,
                                                    hasLyric: hasLyric) {
                                            
                                            if count % 49 == 0 {
                                                delegate?.musicLoading(musicsLoaded: count, totalTime: totalTime)
                                            }
                                            count += 1
                                            countDir += 1
                                            totalTime += Double(duration)
                                            totalTimeDir += Double(duration)
                                        }
                                    }
                                    catch {
                                        print(error)
                                    }
                                }
                            }
                        }
                    }
                }
                completion(count)
            }
            if !updateDirData(dirPath: dir.path, countDir: countDir, totalTimeDir: totalTimeDir) {
                print("Falha ao atualizar diretório.")
            }
        }
    }
    
    private func saveServerInfo() {
        if let deviceName = Host.current().localizedName {
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMddHHmmss"
            let lastUpdate = dateFormatter.string(from: Date())
            
            let defaults = UserDefaults.standard
            defaults.set(deviceName, forKey: "ServerName")
            defaults.set(count, forKey: "MusicsCount")
            defaults.set(lastUpdate, forKey: "LastUpdate")
        }
    }
    
    func updateDirData(dirPath: String, countDir: Int, totalTimeDir: Double) -> Bool {
        let descriptor = FetchDescriptor<MusicDirectory>(
            predicate: #Predicate { $0.path == dirPath }
        )
        
        do {
            let directories = try modelContext.fetch(descriptor)
            if let directory = directories.first {
                directory.musicCount = countDir
                directory.totalTime = totalTimeDir
                try modelContext.save()
                return true
            }
        } catch {
            print("Erro ao atualizar diretório: \(error)")
        }
        return false
    }
    
    func getDirectories() -> [MusicDirectory] {
        let descriptor = FetchDescriptor<MusicDirectory>(
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Erro ao buscar diretórios: \(error)")
            return []
        }
    }
    
    func addDirectory(dirPath: String) -> Bool {
        let newDirectory = MusicDirectory(path: dirPath, musicCount: 0, totalTime: 0.0)
        modelContext.insert(newDirectory)
        
        do {
            try modelContext.save()
            return true
        } catch {
            print("Erro ao adicionar diretório: \(error)")
            return false
        }
    }
    
    func deleteDirectory(dirName: String) -> Bool {
        let descriptor = FetchDescriptor<MusicDirectory>(
            predicate: #Predicate { $0.name == dirName }
        )
        
        do {
            let directories = try modelContext.fetch(descriptor)
            for directory in directories {
                modelContext.delete(directory)
            }
            try modelContext.save()
            return true
        } catch {
            print("Erro ao deletar diretório: \(error)")
            return false
        }
    }
    
    func cleanMusicsTables() {
        do {
            // Deletar todos os registros de Music
            let musicDescriptor = FetchDescriptor<Music>()
            let allMusics = try modelContext.fetch(musicDescriptor)
            for music in allMusics {
                modelContext.delete(music)
            }
            
            // Deletar todos os álbuns
            let albumDescriptor = FetchDescriptor<Album>()
            let allAlbums = try modelContext.fetch(albumDescriptor)
            for album in allAlbums {
                modelContext.delete(album)
            }
            
            // Deletar todos os artistas
            let artistDescriptor = FetchDescriptor<Artist>()
            let allArtists = try modelContext.fetch(artistDescriptor)
            for artist in allArtists {
                modelContext.delete(artist)
            }
            
            try modelContext.save()
        } catch {
            print("Erro ao limpar tabelas: \(error)")
        }
    }
       
    func musicExists(filePath: String) -> Bool {
        let descriptor = FetchDescriptor<Music>(
            predicate: #Predicate { $0.filePath == filePath }
        )
        
        do {
            let musics = try modelContext.fetch(descriptor)
            return !musics.isEmpty
        } catch {
            print("Erro ao verificar existência de música: \(error)")
            return false
        }
    }
    
    func addMusic(filePath: String, musicTitle: String, artist: String, album: String, year: String, track: Int, duration: Int, genre: String, hasLyric: Bool) -> Bool {
        do {
            // Criar ou buscar artista
            var artistObj = try findOrCreateArtist(name: artist, genre: genre)
            
            // Criar ou buscar álbum
            var albumObj = try findOrCreateAlbum(name: album, year: year, artist: artist, genre: genre)
            
            // Criar música
            let newMusic = Music(
                idServer: 0,
                artist: artist,
                album: album,
                year: year,
                track: track,
                musicTitle: musicTitle,
                genre: genre,
                duration: duration,
                filePath: filePath,
                hasLyric: hasLyric
            )
            
            modelContext.insert(newMusic)
            
            // Adicionar música ao álbum
            let albumMusic = AlbumMusic(
                idServer: 0,
                track: track,
                musicTitle: musicTitle,
                duration: duration,
                filePath: filePath
            )
            modelContext.insert(albumMusic)
            albumObj.musics.append(albumMusic)
            
            // Adicionar música ao artista
            if let artistAlbum = artistObj.albuns.first(where: { $0.album == album }) {
                let artistMusic = ArtistMusic(
                    idServer: 0,
                    track: track,
                    musicTitle: musicTitle,
                    duration: duration,
                    filePath: filePath
                )
                modelContext.insert(artistMusic)
                artistAlbum.musics.append(artistMusic)
            } else {
                let newArtistAlbum = ArtistAlbum(album: album, year: year)
                modelContext.insert(newArtistAlbum)
                
                let artistMusic = ArtistMusic(
                    idServer: 0,
                    track: track,
                    musicTitle: musicTitle,
                    duration: duration,
                    filePath: filePath
                )
                modelContext.insert(artistMusic)
                newArtistAlbum.musics.append(artistMusic)
                artistObj.albuns.append(newArtistAlbum)
            }
            
            try modelContext.save()
            return true
        } catch {
            print("Erro ao adicionar música: \(error)")
            return false
        }
    }
    
    private func findOrCreateArtist(name: String, genre: String) throws -> Artist {
        let descriptor = FetchDescriptor<Artist>(
            predicate: #Predicate { $0.artist == name }
        )
        
        let artists = try modelContext.fetch(descriptor)
        if let existingArtist = artists.first {
            return existingArtist
        } else {
            let newArtist = Artist(artist: name, genre: genre)
            modelContext.insert(newArtist)
            return newArtist
        }
    }
    
    private func findOrCreateAlbum(name: String, year: String, artist: String, genre: String) throws -> Album {
        let descriptor = FetchDescriptor<Album>(
            predicate: #Predicate { $0.album == name && $0.year == year && $0.artist == artist }
        )
        
        let albums = try modelContext.fetch(descriptor)
        if let existingAlbum = albums.first {
            return existingAlbum
        } else {
            let newAlbum = Album(album: name, artist: artist, year: year, genre: genre)
            modelContext.insert(newAlbum)
            return newAlbum
        }
    }
    
    private func updateDirectoryNames() -> Bool {
        let descriptor = FetchDescriptor<MusicDirectory>(
            sortBy: [SortDescriptor(\.path)]
        )
        
        do {
            let directories = try modelContext.fetch(descriptor)
            var count = 1
            for directory in directories {
                directory.name = "Dir \(String(format: "%02d", count))"
                count += 1
            }
            try modelContext.save()
            return true
        } catch {
            print("Erro ao atualizar nomes de diretórios: \(error)")
            return false
        }
    }
}

