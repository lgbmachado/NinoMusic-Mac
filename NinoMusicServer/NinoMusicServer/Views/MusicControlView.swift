//
//  MusicControlView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 07/08/24.
//

import SwiftUI
import AVFAudio
import ID3TagEditor

struct MusicControlView: View {
    @Binding var music: Music
    @Binding var musics: Musics
    @Binding var idMusicSelected: Music.ID
    
    @State var duration: Double = 0
    @State var position: Double = 0
    @State var timeDuration: String = ""
    @State var timePosition: String = ""
    @State var player: AVAudioPlayer?
    @State var isPlaying : Bool = false
    @State var imgCover: NSImage?
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            HStack {
                Button("", systemImage: "backward.circle", action: {PreviusSong()})
                    .font(.system(size: 20))
                    .buttonStyle(.borderless)
//                    .disabled(isPlaying)
                Button("", systemImage: "playpause.circle", action: {
                    PlayPauseSong(pathMusic: music.filePath)
                })
                    .font(.system(size: 20))
                    .buttonStyle(.borderless)
                Button("", systemImage: "forward.circle", action: {NextSong()})
                    .font(.system(size: 20))
                    .buttonStyle(.borderless)
//                    .disabled(isPlaying)
                Spacer(minLength: 30)
                VStack {
                    Slider(value: $position, in: 0...duration)
                        .frame(width: 200, height: 20)
                        .onReceive(timer) {_ in
                            self.position = player?.currentTime ?? 0
                        }
                    Text(verbatim: isPlaying ? "\(timePosition) / \(timeDuration)" : "")
                        .font(.caption2)
                        .onReceive(timer) {_ in
                            let ti = NSInteger(player?.currentTime ?? 0)
                            let seconds = ti % 60
                            let minutes = (ti / 60) % 60
                            timePosition = String(format: "%0.2d:%0.2d",minutes,seconds)
                        }
                }
                
                Spacer(minLength: 30)
                Image(nsImage: getCoverMusic(musicPath: music.filePath))
                    .resizable()
                    .frame(width: 49, height: 49, alignment: .bottom)
                    .scaledToFit()
                    .aspectRatio(contentMode: .fit)
                    .border(.black)
                VStack(alignment: .leading, spacing: 6) {
                    Text(verbatim: music.musicTitle)
                        .font(.title3)
                    Text(verbatim: music.artist)
                        .font(.caption2)
                }
                
            }
        }
    }
    
    func PreviusSong() {
        let pos = music.count - 1
        if pos >= 1 {
            if let musicSelected = musics.musics.first(where: {$0.count == pos}) {
                music = musicSelected
                idMusicSelected = musicSelected.id
            }
        }
    }
    
    func getCoverMusic(musicPath:String) -> NSImage {
        let id3TagEditor: ID3TagEditor = ID3TagEditor()
        do {
            let id3Tag = try id3TagEditor.read(from: musicPath.replacingOccurrences(of: "file://", with: "").replacingOccurrences(of: "%20", with: " "))
                        
            if let coverImage = id3Tag?.frames[.attachedPicture(.frontCover)] as? ID3FrameAttachedPicture {
                return NSImage(data: coverImage.picture) ?? NSImage()
            }
        }
        catch {
            print(error)
        }
        return NSImage()
    }
    
    func PlayPauseSong(pathMusic: String?) {
        if !isPlaying {
            if let url = URL(string: pathMusic ?? "") {
                do {
                    player = try AVAudioPlayer(contentsOf: url)
                    player?.prepareToPlay()
                    
                    duration = player?.duration ?? 0
                    
                    let ti = NSInteger(player?.duration ?? 0)
                    let seconds = ti % 60
                    let minutes = (ti / 60) % 60
                    timeDuration = String(format: "%0.2d:%0.2d",minutes,seconds)
                    
                    player?.isMeteringEnabled = true
                    player?.play()
                    isPlaying = true

                } catch let error as NSError {
                    print(error.description)
                }
            }
        } else {
            player?.pause()
            isPlaying = false
        }
    }
    
    func NextSong() {
        let pos = music.count + 1
        if pos <= musics.musics.count {
            if let musicSelected = musics.musics.first(where: {$0.count == pos}) {
                music = musicSelected
                idMusicSelected = musicSelected.id
            }
        }
    }
}

#Preview {
    MusicControlView(music: .constant(Music.example), musics: .constant(Musics()), idMusicSelected: .constant(UUID()))
}
