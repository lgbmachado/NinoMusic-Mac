//
//  MusicPlayerViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/09/25.
//

import Foundation
import Combine
import AVFAudio
import AppKit

enum NavigationKind {
    case next
    case previus
}

class MusicPlayerViewModel: NSObject, ObservableObject {
    @Published var currentMusic: Music?
    @Published var isPlaying: Bool = false
    @Published var duration: Double = 0
    @Published var position: Double = 0
    @Published var timeDuration: String = "00:00"
    @Published var timePosition: String = "00:00"
    
    private var player: AVAudioPlayer?
    
    func setMusicSelected(music: Music) {
        currentMusic = music
    }
    
    func setMusicAlbumSelected(music: AlbumMusic) {
        currentMusic?.id = music.id
        currentMusic?.seq = music.seq
        currentMusic?.track = music.track
        currentMusic?.musicTitle = music.musicTitle
        currentMusic?.duration = music.duration
        currentMusic?.filePath = music.filePath
    }
    
    // Métodos de controle
    func play() {
        self.isPlaying = true
        
        if let url = URL(string: self.currentMusic?.filePath ?? "") {
            do {
                self.player = try AVAudioPlayer(contentsOf: url)
                self.player?.prepareToPlay()
                
                self.duration = player?.duration ?? 0
                
                let ti = NSInteger(player?.duration ?? 0)
                let seconds = ti % 60
                let minutes = (ti / 60) % 60
                self.timeDuration = String(format: "%0.2d:%0.2d",minutes,seconds)
                
                self.player?.isMeteringEnabled = true
                self.player?.play()
                self.isPlaying = true
                
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                    self.position = self.player?.currentTime ?? 0
                    let seconds = NSInteger(self.position) % 60
                    self.timePosition = "\(String().secondsToTime(seconds: seconds))"
                    
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
        // Lógica para pausar reprodução
    }
    
    func resume() {
        self.isPlaying = true
        self.player?.play()
    }
    
    func stop() {
        self.isPlaying = false
        self.currentMusic = nil
        // Lógica para parar reprodução
    }
    
    func navigateSongs(kind: NavigationKind) {
//        let searchCount = kind == .next ? musicSelected.seq + 1 : musicSelected.seq - 1
//        if let selected = self.musics.first(where: {$0.seq == searchCount}) {
//            self.currentMusic?.id = selected.id
//            self.currentMusic = selected
//            self.player?.stop()
//            self.isPlaying = false
//            playPauseSong()
//        }
    }
    
    func setMusicPosition(newPosition: Double) {
        self.player?.pause()
        self.player?.currentTime = newPosition
        self.player?.play()
    }
    
    //    func navigateSongs(kind: NavigationKind) {
    //        let searchCount = kind == .next ? musicSelected.seq + 1 : musicSelected.seq - 1
    //        if let selected = self.musics.first(where: {$0.seq == searchCount}) {
    //            self.idMusicSelected = selected.id
    //            self.musicSelected = selected
    //            self.player?.stop()
    //            self.isPlaying = false
    //            playPauseSong()
    //        }
    //    }
    
    //    func playPauseSong() {
    //        if !self.isPlaying {
    //            if let url = URL(string: self.musicSelected.filePath) {
    //                do {
    //                    self.player = try AVAudioPlayer(contentsOf: url)
    //                    self.player?.delegate  = self
    //                    self.player?.prepareToPlay()
    //
    //                    self.duration = player?.duration ?? 0
    //
    //                    let ti = NSInteger(player?.duration ?? 0)
    //                    let seconds = ti % 60
    //                    let minutes = (ti / 60) % 60
    //                    self.timeDuration = String(format: "%0.2d:%0.2d",minutes,seconds)
    //
    //                    self.player?.isMeteringEnabled = true
    //                    self.player?.play()
    //                    self.isPlaying = true
    //
    //                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
    //                        self.position = self.player?.currentTime ?? 0
    //                        let seconds = NSInteger(self.position) % 60
    //                        self.timePosition = "\(String().secondsToTime(seconds: seconds))"
    //
    //                        if !self.isPlaying {
    //                            timer.invalidate()
    //                            self.timeDuration = "00:00"
    //                            self.timePosition = "00:00"
    //                        }
    //                    }
    //                } catch let error as NSError {
    //                    print(error.description)
    //                }
    //            }
    //        } else {
    //            self.player?.pause()
    //            self.isPlaying = false
    //        }
    //    }
    
    //    func setMusicPosition(newPosition: Double) {
    //        self.player?.pause()
    //        self.player?.currentTime = newPosition
    //        self.player?.play()
    //    }
    
    //extension MusicsViewModel: AVAudioPlayerDelegate {
    //
    //    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    //        if flag {
    //            self.player?.stop()
    //            self.isPlaying = false
    //            navigateSongs(kind: .next)
    //            playPauseSong()
    //        }
    //    }
    //}
    
    func getImageCover() -> NSImage {
        return Id3TagUtils.getImageCover(path: self.currentMusic?.filePath ?? "")
    }
    
    func getLyrics() -> String {
        return Id3TagUtils.getLyrics(path: self.currentMusic?.filePath ?? "")
    }
    
}
