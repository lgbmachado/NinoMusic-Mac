//
//  MusicFiles.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 27/08/24.
//

import AVFoundation
import Foundation
import ID3TagEditor

protocol MusicFilesDelegate {
    func musicLoading(musicsLoaded: Int, totalTime: TimeInterval)
}

class MusicFiles {
    
    private var count = 0
    private let musicDb = Database()
    
    var delegate: MusicFilesDelegate?
    var directories = [Directory]()
    var musics = [Music]()
    var albuns = [Album]()
    var totalTime: TimeInterval = 0
    
    init() {
        self.directories = musicDb.getDirectories()
        self.musics = musicDb.getMusics()
        self.albuns = self.musicDb.getAlbuns()
    }
    
    func addDirectory(dirPath: String) async {
        if musicDb.addDirectory(dirPath: dirPath) {
            self.directories = musicDb.getDirectories()
            await updateMusicsDatabase { _ in
                self.musics = self.musicDb.getMusics()
                self.albuns = self.musicDb.getAlbuns()
                self.saveServerInfo()
            }
        }
    }
    
    func deleteDirectory(dirName: String) async {
        if musicDb.deleteDirectory(dirName: dirName) {
            self.directories = self.musicDb.getDirectories()
            await updateMusicsDatabase { _ in
                self.musics = self.musicDb.getMusics()
                self.albuns = self.musicDb.getAlbuns()
                self.saveServerInfo()
            }
        }
    }
    
    private func updateMusicsDatabase(completion: @escaping (Int?) -> ()) async {
        musicDb.cleanMusicsTables()
        for dir in self.directories {
            let url = URL(fileURLWithPath: dir.path)
            var directories = [URL]()
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
                                if !self.musicDb.musicExists(filePath: fileURL.absoluteString) {
                                    do {
                                        let id3Tag = try id3TagEditor.read(from: fileURL.path)
                                        
                                        let artist = ((id3Tag?.frames[.artist] as? ID3FrameWithStringContent)?.content ?? String()) as String
                                        let album = ((id3Tag?.frames[ .album] as? ID3FrameWithStringContent)?.content ?? String()) as String
                                        let year = ((id3Tag?.frames[.recordingYear] as? ID3FrameWithIntegerContent)?.value ?? Int()) as Int
                                        let track = ((id3Tag?.frames[.trackPosition] as? ID3FramePartOfTotal)?.part ?? Int()) as Int
                                        let duration = await getDuration(url: fileURL)
                                        let musicTitle = ((id3Tag?.frames[.title] as? ID3FrameWithStringContent)?.content ?? String()) as String
                                        let genre = ((id3Tag?.frames[.genre] as? ID3FrameGenre)?.description ?? String()) as String
                                        let filePath = fileURL.absoluteString
                                        
                                        if self.musicDb.AddMusic(filePath: filePath,
                                                                 musicTitle: musicTitle,
                                                                 artist: artist,
                                                                 album: album,
                                                                 year: year,
                                                                 track: track,
                                                                 duration: duration,
                                                                 genre: genre) {
                                            
                                            if count % 49 == 0 {
                                                delegate?.musicLoading(musicsLoaded: count, totalTime: totalTime)
                                            }
                                            count += 1
                                            totalTime += Double(duration)
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
        }
    }
    
//    private func updateMusicsDatabase(completion: @escaping (Int?) -> ()) async {
//        musicDb.cleanMusicsTables()
//        for dir in self.directories {
//            let url = URL(fileURLWithPath: dir.path)
//            var directories = [URL]()
//            if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
//                for case let dirURL as URL in enumerator {
//                    do {
//                        let dirAttributes = try dirURL.resourceValues(forKeys:[.isDirectoryKey])
//                        if dirAttributes.isDirectory! {
//                            directories.append(dirURL)
//                        }
//                    } catch { print(error, dirURL) }
//                }
//                let id3TagUtils = Id3TagUtils()
//                
//                for urlDir in directories {
//                    if let enumFiles = FileManager.default.enumerator(at: urlDir, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
//                        for case let fileURL as URL in enumFiles {
//                            if fileURL.pathExtension.uppercased() == "MP3" {
//                                if !self.musicDb.musicExists(filePath: fileURL.absoluteString) {
//                                    let duration = await id3TagUtils.getDuration(path: fileURL.path)
//                                    let filePath = fileURL.absoluteString
//                                    
//                                    let track = id3TagUtils.getTrack(path: fileURL.path)
//                                    
//                                    if self.musicDb.AddMusic(filePath: filePath,
//                                                             musicTitle: id3TagUtils.getTitle(path: fileURL.path),
//                                                             artist: id3TagUtils.getArtist(path: fileURL.path),
//                                                             album: id3TagUtils.getAlbum(path: fileURL.path),
//                                                             year: id3TagUtils.getYear(path: fileURL.path),
//                                                             track: track,
//                                                             duration: duration,
//                                                             genre: id3TagUtils.getGenre(path: fileURL.path)) {
//                                        
//                                        if count % 49 == 0 {
//                                            delegate?.musicLoading(musicsLoaded: count, totalTime: totalTime)
//                                        }
//                                        count += 1
//                                        totalTime += Double(duration)
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//                completion(count)
//            }
//        }
//    }
    
    private func getDuration(url: URL) async -> Int {
        do {
            let audioAsset = AVURLAsset.init(url: url, options: nil)
            let duration = try await audioAsset.load(.duration)
            return ("\(CMTimeGetSeconds(duration))" as NSString).integerValue
        } catch {
            return 0
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
}


