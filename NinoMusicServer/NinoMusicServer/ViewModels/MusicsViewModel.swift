//
//  MusicsViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 12/03/25.
//

import AVFAudio
import Foundation
import ID3TagEditor
import SwiftUI

enum NavigationKind {
    case next
    case previus
}

class MusicsViewModel: NSObject, ObservableObject {
    
    @Published var musics: [Music] = []
    @Published var idMusicSelected: Music.ID = UUID()
    @Published var fileSelected: String = String()
    @Published var musicSelected: Music = Music.emptyMusic
    @Published var duration: Double = 0
    @Published var position: Double = 0
    @Published var timeDuration: String = "00:00"
    @Published var timePosition: String = "00:00"
    @Published var isPlaying: Bool = false
    
    private var player: AVAudioPlayer?
    
    func reloadMusics() {
        self.musics = MusicFiles().musics
    }
    
    func setIdSelection(selection: Music.ID) {
        self.idMusicSelected = selection
        if let item = self.musics.first(where: { $0.id == self.idMusicSelected }) {
            self.musicSelected = item
            self.fileSelected = String((item.filePath as NSString).lastPathComponent).replacingOccurrences(of: "%20", with: " ")
        } else {
            self.musicSelected = Music.emptyMusic
        }
    }
    
    func navigateSongs(kind: NavigationKind) {
        let searchCount = kind == .next ? musicSelected.count + 1 : musicSelected.count - 1
        if let selected = self.musics.first(where: {$0.count == searchCount}) {
            self.idMusicSelected = selected.id
            self.musicSelected = selected
            self.player?.stop()
            self.isPlaying = false
            playPauseSong()
        }
    }
    
    func getCoverMusic() -> NSImage {
        let id3TagEditor: ID3TagEditor = ID3TagEditor()
        do {
            let id3Tag = try id3TagEditor.read(from: self.musicSelected.filePath.replacingOccurrences(of: "file://", with: "").replacingOccurrences(of: "%20", with: " "))
            
            if let coverImage = id3Tag?.frames[.attachedPicture(.frontCover)] as? ID3FrameAttachedPicture {
                return NSImage(data: coverImage.picture) ?? NSImage()
            }
        }
        catch {
            print(error)
        }
        return NSImage()
    }
    
    func playPauseSong() {
        if !self.isPlaying {
            if let url = URL(string: self.musicSelected.filePath) {
                do {
                    self.player = try AVAudioPlayer(contentsOf: url)
                    self.player?.delegate  = self
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
        } else {
            self.player?.pause()
            self.isPlaying = false
        }
    }
    
    func setMusicPosition(newPosition: Double) {
        self.player?.pause()
        self.player?.currentTime = newPosition
        self.player?.play()
    }
}

extension MusicsViewModel: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            self.player?.stop()
            self.isPlaying = false
            navigateSongs(kind: .next)
            playPauseSong()
        }
    }
}
