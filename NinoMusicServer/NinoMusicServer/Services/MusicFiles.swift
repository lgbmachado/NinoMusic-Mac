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
    func musicLoading(musicsLoaded: Int)
}

class MusicFiles {
    
    private var count = 0
    var delegate: MusicFilesDelegate?
    
    let musicDb = Database()
    
    func loadMusics(path: String, completion: @escaping (Int?) -> ()) async {
        let url = URL(fileURLWithPath: path)
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
                                    
                                    let artist = ((id3Tag?.frames[.artist] as? ID3FrameWithStringContent)?.content ?? "") as String
                                    let album = ((id3Tag?.frames[ .album] as? ID3FrameWithStringContent)?.content ?? "") as String
                                    let year = ((id3Tag?.frames[.recordingYear] as? ID3FrameWithIntegerContent)?.value ?? 0) as Int
                                    let track = ((id3Tag?.frames[.trackPosition] as? ID3FramePartOfTotal)?.part ?? 0) as Int
                                    let duration = await getDuration(url: fileURL)
                                    let musicTitle = ((id3Tag?.frames[.title] as? ID3FrameWithStringContent)?.content ?? "") as String
                                    let genre = ((id3Tag?.frames[.genre] as? ID3FrameGenre)?.description ?? "") as String
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
                                            delegate?.musicLoading(musicsLoaded: count)
                                        }
                                        count += 1
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
            self.musicDb.closeDatabase()
            
            if let deviceName = Host.current().localizedName {
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMddHHmmss"
                let lastUpdate = dateFormatter.string(from: Date())
                
                let defaults = UserDefaults.standard
                defaults.set(deviceName, forKey: "ServerName")
                defaults.set(count, forKey: "MusicsCount")
                defaults.set(lastUpdate, forKey: "LastUpdate")
            }
            completion(count)
        }
        
        func getDuration(url: URL) async -> Int {
            do {
                let audioAsset = AVURLAsset.init(url: url, options: nil)
                let duration = try await audioAsset.load(.duration)
                return ("\(CMTimeGetSeconds(duration))" as NSString).integerValue
            } catch {
                return 0
            }
            
            
        }
    }
}

