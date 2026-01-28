//
//  MusicPlayerView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/09/25.
//

import SwiftUI

struct MusicPlayerView: View {
    @ObservedObject var musicsPlayerViewModel: MusicPlayerViewModel
    @Binding var selection: UUID?
    
    @State private var isMovingSlider = false
    @State var dragGestureValue: DragGesture.Value?
    @State private var showingLyrics = false
    
    var body: some View {
        
        VStack {
            HStack {
                Button(String(), systemImage: "backward.circle", action: {
                    NotificationCenter.default.post(name: Notification.Name("previousTapped"),
                                                    object: nil,
                                                    userInfo: ["origin" : musicsPlayerViewModel.originCurrentMusic as Any])
                    if self.musicsPlayerViewModel.isPlaying {
                        self.musicsPlayerViewModel.play()
                    }
                })
                .font(.system(size: 30))
                .buttonStyle(.borderless)
                Button(String(), systemImage: "playpause.circle", action: {
                    if self.musicsPlayerViewModel.isPlaying {
                        self.musicsPlayerViewModel.pause()
                    }else {
                        self.musicsPlayerViewModel.play()
                    }
                    
                })
                .font(.system(size: 30))
                .buttonStyle(.borderless)
                Button(String(), systemImage: "forward.circle", action: {
                    NotificationCenter.default.post(name: Notification.Name("nextTapped"),
                                                    object: nil,
                                                    userInfo: ["origin" : musicsPlayerViewModel.originCurrentMusic as Any])
                    if self.musicsPlayerViewModel.isPlaying {
                        self.musicsPlayerViewModel.play()
                    }
                })
                .font(.system(size: 30))
                .buttonStyle(.borderless)
                Spacer(minLength: 15)
                Button(String(), systemImage: "music.note.tv", action: {
                    if musicsPlayerViewModel.currentMusic?.hasLyric ?? false {
                        showingLyrics.toggle()
                    }
                })
                .font(.system(size: 30))
                .buttonStyle(.borderless)
                VStack {
                    Slider(value: $musicsPlayerViewModel.position, in: 0...musicsPlayerViewModel.duration, onEditingChanged: { editing in
                        isMovingSlider = editing
                        if !isMovingSlider {
                            self.musicsPlayerViewModel.setMusicPosition(newPosition: musicsPlayerViewModel.position)
                        }
                    })
                        .frame(width: 200, height: 20)
                    Text(verbatim: musicsPlayerViewModel.isPlaying ? "\(musicsPlayerViewModel.timePosition) / \(musicsPlayerViewModel.timeDuration)" : "00:00 / 00:00")
                        .font(.caption2)
                }
                
                Spacer(minLength: 15)
                Image(nsImage: musicsPlayerViewModel.getImageCover() ?? NSImage())
                    .resizable()
                    .frame(width: 49, height: 49, alignment: .bottom)
                    .scaledToFit()
                    .aspectRatio(contentMode: .fit)
                    .border(.black)
                VStack(alignment: .leading, spacing: 6) {
                    Text(verbatim: musicsPlayerViewModel.currentMusic?.musicTitle ?? "")
                        .font(.title3)
                    Text(verbatim: musicsPlayerViewModel.currentMusic?.artist ?? "")
                        .font(.caption2)
                }
            }
        }
        .sheet(isPresented: $showingLyrics) {
            LyricView(lyricText: musicsPlayerViewModel.getLyrics() ?? "Falha ao obter letra da música \"\(musicsPlayerViewModel.currentMusic?.musicTitle ?? "Desconhecida")\".")
            
        }
    }
}
