//
//  MusicPlayerView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/09/25.
//

import SwiftUI

struct MusicPlayerView: View {
    @ObservedObject var musicsPlayerViewModel: MusicPlayerViewModel
    @Binding var selection: Music.ID?
    
    @State private var isMovingSlider = false
    @State var dragGestureValue: DragGesture.Value?
    @State private var showingLyrics = false
    
    var body: some View {
        
        VStack {
            HStack {
                Button(String(), systemImage: "backward.circle", action: {
                    self.musicsPlayerViewModel.navigateSongs(kind: .previus)
//                    selection = self.musicsViewModel.idMusicSelected
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
//                    self.musicsViewModel.navigateSongs(kind: .next)
                })
                .font(.system(size: 30))
                .buttonStyle(.borderless)
                Spacer(minLength: 15)
                VStack {
//                    Slider(value: $musicsPlayerViewModel.position, in: 0...self.musicsViewModel.duration, onEditingChanged: { editing in
//                        isMovingSlider = editing
//                        if !isMovingSlider {
//                            self.musicsPlayerViewModel.setMusicPosition(newPosition: musicsViewModel.position)
//                        }
//                    })
//                        .frame(width: 200, height: 20)
//                    Text(verbatim: self.musicsViewModel.isPlaying ? "\(self.musicsViewModel.timePosition) / \(self.musicsViewModel.timeDuration)" : "00:00 / 00:00")
//                        .font(.caption2)
                }
                
                Spacer(minLength: 15)
                Image(nsImage: musicsPlayerViewModel.getImageCover())
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
                Spacer(minLength: 15)
                Button(String(), systemImage: "music.note.tv", action: {
                    if musicsPlayerViewModel.currentMusic?.hasLyric ?? false {
                        showingLyrics.toggle()
                    }
                })
                .font(.system(size: 30))
                .buttonStyle(.borderless)
            }
        }
        .sheet(isPresented: $showingLyrics) {
            LyricView(lyricText: musicsPlayerViewModel.getLyrics())
            
        }
    }
}
