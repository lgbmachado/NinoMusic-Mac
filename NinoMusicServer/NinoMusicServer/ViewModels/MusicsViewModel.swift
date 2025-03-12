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

class MusicsViewModel: ObservableObject {
    @Published var musics: [Music] = []
    @Published var idMusicSelected: Music.ID = UUID()
    @Published var musicSelected: Music = Music.emptyMusic
    @Published var duration: Double = 0
    @Published var position: Double = 0
    @Published var timeDuration: String = "00:00"
    @Published var timePosition: String = "00:00"
    @Published var isPlaying: Bool = false
    @Published var totalMusics: Int = 0
    
    @Published var directories = Directories().dirs
    
    private var player: AVAudioPlayer?
    
    func loadMusics() {
        let musicDb = Database()
        self.musics = musicDb.getMusics()
    }
    
    func setIdSelection(selection: Music.ID) {
        self.idMusicSelected = selection
        if let item = musics.first(where: { $0.id == self.idMusicSelected }) {
            self.musicSelected = item
        } else {
            self.musicSelected = Music.emptyMusic
        }
    }
    
    func navigateSongs(kind: NavigationKind) {
        let searchCount = kind == .next ? musicSelected.count + 1 : musicSelected.count - 1
        if let selected = musics.first(where: {$0.count == searchCount}) {
            self.idMusicSelected = selected.id
            self.musicSelected = selected
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
                        
                        let ti = NSInteger(self.player?.currentTime ?? 0)
                        let seconds = ti % 60
                        let minutes = (ti / 60) % 60
                        self.timePosition = String(format: "%0.2d:%0.2d",minutes,seconds)

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
    
    func addDirectory() {
        let dialog = NSOpenPanel()
        dialog.title = String(localized: "text_select_dir")
        dialog.showsHiddenFiles = false;
        dialog.canChooseFiles = false;
        dialog.canChooseDirectories = true;
        
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            if let result = dialog.url {
                self.directories.append(Directory(name: "Dir \(directories.count + 1)",
                                             path: result.path))
                Directories().dirs = directories
                let musicDb = Database()
                musicDb.cleanTables()
            }
        } else {
            return
        }
    }
    
    func deleteDirectory(selection: UUID) {
        if directories.count > 0 {
            let modstations = directories.filter{ $0.id != selection}
            Directories().dirs = modstations
            directories = Directories().dirs
            let musicDb = Database()
            musicDb.cleanTables()
        }
    }
    
    func updateMusicsDatabase() async {
        self.totalMusics = 0
        let musicFiles = MusicFiles()
        for i in 0..<Directories().dirs.count {
            await musicFiles.loadMusics(path: Directories().dirs[i].path) { musicsLoaded in
                if let musicsLoaded = musicsLoaded {
                    self.totalMusics += musicsLoaded
                    DispatchQueue.main.async {
                        let musicDb = Database()
                        self.musics = musicDb.getMusics()
                    }
                }
            }
        }
    }
}
