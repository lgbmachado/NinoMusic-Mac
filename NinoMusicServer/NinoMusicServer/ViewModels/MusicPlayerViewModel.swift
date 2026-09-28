//
//  MusicPlayerViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/09/25.
//

import Foundation
import AVFAudio
import AppKit

enum NavigationKind {
    case next
    case previus
}

class MusicPlayerViewModel: NSObject, ObservableObject {
    @Published var currentMusic: Music?
    @Published var originCurrentMusic: MusicContentViewType?
    @Published var isPlaying: Bool = false
    @Published var duration: Double = 0
    @Published var position: Double = 0
    @Published var timeDuration: String = "00:00"
    @Published var timePosition: String = "00:00"
    
    private var player: AVAudioPlayer?
    private let helper = DbHelper(path: DbConstants.databasePath)
    
    override init() {
        self.player = AVAudioPlayer()
    }
    
    func setMusicSelected(music: Music) {
        currentMusic = music
    }

    func play() {
        self.isPlaying = true
        
        if let url = URL(string: self.currentMusic?.filePath ?? "") {
            do {
                if let player = self.player, player.isPlaying {
                    player.stop()
                }
                self.player = try AVAudioPlayer(contentsOf: url)
                self.player?.delegate = self
                self.player?.prepareToPlay()
                
                self.duration = player?.duration ?? 0
                self.timeDuration = String().secondsToTime(seconds: Int(self.duration))
                
                self.player?.isMeteringEnabled = true
                self.player?.play()
                self.isPlaying = true
                self.registerExecution()
                
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                    self.position = self.player?.currentTime ?? 0
                    self.timePosition = String().secondsToTime(seconds: Int(self.position))
                    if !self.isPlaying {
                        timer.invalidate()
                        self.timeDuration = "00:00"
                        self.timePosition = "00:00"
                    }
                }
            } catch let error as NSError {
                print(error.description)
            }
        }
    }
    
    func pause() {
        self.isPlaying = false
        self.player?.pause()
    }
    
    func resume() {
        self.isPlaying = true
        self.player?.play()
    }
    
    func stop() {
        self.player?.stop()
        self.isPlaying = false
        self.currentMusic = nil
    }
    
    func setMusicPosition(newPosition: Double) {
        self.player?.pause()
        self.player?.currentTime = newPosition
        self.position = self.player?.currentTime ?? 0
        self.timePosition = String().secondsToTime(seconds: Int(self.position))
        self.player?.play()
    }
    
    func getImageCover() -> NSImage? {
        return Id3TagUtils.getImageCover(path: self.currentMusic?.filePath ?? "")
    }
    
    func getLyrics() -> String? {
        return Id3TagUtils.getLyrics(path: self.currentMusic?.filePath ?? "")
    }
    
    private func registerExecution() {
        guard let idServer = self.currentMusic?.idServer, idServer > 0 else { return }
        let now = Int(Date().timeIntervalSince1970)
        let update = """
            UPDATE \(DbConstants.TableMusic.tableName)
            SET
               \(DbConstants.TableMusic.colLastExecution) = \(now),
               \(DbConstants.TableMusic.colCountExecution) = \(DbConstants.TableMusic.colCountExecution) + 1
            WHERE
               \(DbConstants.TableMusic.colMusicId) = \(idServer)
            """
        guard self.helper?.executeQuery(query: update) == true else { return }
        
        let select = """
            SELECT \(DbConstants.TableMusic.colCountExecution)
            FROM \(DbConstants.TableMusic.tableName)
            WHERE \(DbConstants.TableMusic.colMusicId) = \(idServer)
            """
        var countExecution = (self.currentMusic?.countExecution ?? 0) + 1
        if let count = (try? self.helper?.sql(query: select))?.first?[DbConstants.TableMusic.colCountExecution] as? Int {
            countExecution = count
        }
        let lastExecution = Date(timeIntervalSince1970: TimeInterval(now))
        
        self.currentMusic?.lastExecution = lastExecution
        self.currentMusic?.countExecution = countExecution
        NotificationCenter.default.post(name: Notification.Name("musicExecuted"),
                                        object: nil,
                                        userInfo: ["idServer": idServer,
                                                   "lastExecution": lastExecution,
                                                   "countExecution": countExecution])
    }
}

extension MusicPlayerViewModel: AVAudioPlayerDelegate {

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            NotificationCenter.default.post(name: Notification.Name("nextTapped"),
                                            object: nil,
                                            userInfo: ["origin" : self.originCurrentMusic as Any])
            self.play()
        }
    }
}
