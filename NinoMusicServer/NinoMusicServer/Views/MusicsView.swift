//
//  MusicsView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import SwiftUI
import AVFAudio
import ID3TagEditor

// MARK: MusicsView
struct MusicsView: View {
    @State var music = Music(count: 0,
                             artist: "",
                             album: "",
                             year: "",
                             track: 0,
                             musicTitle: "",
                             genre: "",
                             filePath: "")
    @State private var sortOrder = [KeyPathComparator(\Music.musicTitle)]
    @State var selection: Music.ID? = nil
    
    @State var duration: Double = 0
    @State var position: Double = 0
    @State var timeDuration: String = ""
    @State var timePosition: String = ""
    @State var player: AVAudioPlayer?
    @State var isPlaying : Bool = false
    @State var imgCover: NSImage?
    
    @Binding var musics: Musics
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var tableData: [Music] {
        return musics.musics.sorted(using: sortOrder)
    }
    
    var body: some View {
            Table(tableData, selection: $selection, sortOrder: $sortOrder) {
                TableColumn(LocalizedStringKey("text_title"), value: \.musicTitle)
                TableColumn(LocalizedStringKey("text_artist"), value: \.artist)
                TableColumn(LocalizedStringKey("text_album"), value: \.album)
                TableColumn(LocalizedStringKey("text_track")) { music in
                    Text("\(music.track)")
                }
                TableColumn(LocalizedStringKey("text_year"), value: \.year)
                TableColumn(LocalizedStringKey("text_genre"), value: \.genre)
            }

        .padding()
        .onChange(of: selection) { selected in
            musics.idMusicSelected = selected ?? UUID()
            if let item = musics.musicSelected {
                music = item
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                VStack {
                    HStack {
                        Button("", systemImage: "backward.circle", action: {PreviusSong()})
                            .font(.system(size: 20))
                            .buttonStyle(.borderless)
                        Button("", systemImage: "playpause.circle", action: {
                            PlayPauseSong(pathMusic: music.filePath)
                        })
                        .font(.system(size: 20))
                        .buttonStyle(.borderless)
                        Button("", systemImage: "forward.circle", action: {NextSong()})
                            .font(.system(size: 20))
                            .buttonStyle(.borderless)
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
        }
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
    
    func PreviusSong() {
        if let musicSelected = musics.musics.first(where: {$0.id == selection}) {
            if let nextMusicSelected = musics.musics.first(where: {$0.count == musicSelected.count - 1}) {
                selection = nextMusicSelected.id
                music = nextMusicSelected
                if isPlaying {
                    player?.stop()
                    isPlaying = false
                    PlayPauseSong(pathMusic: music.filePath)
                }
            }
        }
    }
    
    func NextSong() {
        if let musicSelected = musics.musics.first(where: {$0.id == selection}) {
            if let nextMusicSelected = musics.musics.first(where: {$0.count == musicSelected.count + 1}) {
                selection = nextMusicSelected.id
                music = nextMusicSelected
                if isPlaying {
                    player?.stop()
                    isPlaying = false
                    PlayPauseSong(pathMusic: music.filePath)
                }
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
}

// MARK: MusicRowView
struct MusicRowView: View {
    @State var music: Music
    
    var body: some View {
        GridRow {
            Text(music.musicTitle)
                .bold()
            Text(music.artist)
            Text(music.album)
            Text(String(format: "%d", music.track))
                .gridColumnAlignment(.trailing)
            Text(music.year)
            Text(music.genre)
        }
    }
}

#Preview {
    MusicsView(musics: .constant(Musics()))
}
