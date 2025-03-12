//
//  MusicsView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import SwiftUI

// MARK: MusicsView
struct MusicsView: View {
    @ObservedObject var musicsViewModel: MusicsViewModel
    
    @State private var sortOrder = [KeyPathComparator(\Music.musicTitle)]
    @State var selection: Music.ID? = nil

    var tableData: [Music] {
        return musicsViewModel.musics.sorted(using: sortOrder)
    }
    
    var body: some View {
            Table(tableData, selection: $selection, sortOrder: $sortOrder) {
                TableColumn(LocalizedStringKey("text_title"), value: \.musicTitle)
                TableColumn(LocalizedStringKey("text_artist"), value: \.artist)
                TableColumn(LocalizedStringKey("text_album"), value: \.album)
                TableColumn(LocalizedStringKey("text_track")) { music in
                    Text("\(music.track)")
                }
                .width(40)
                .alignment(.trailing)
                TableColumn(LocalizedStringKey("text_year"), value: \.year)
                    .width(50)
                TableColumn(LocalizedStringKey("text_genre"), value: \.genre)
                    .width(170)
            }

        .padding()
        .onChange(of: selection) { oldSelected, newSelected in
            musicsViewModel.setIdSelection(selection: newSelected ?? UUID())
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                VStack {
                    HStack {
                        Button("", systemImage: "backward.circle", action: {
                            self.musicsViewModel.navigateSongs(kind: .previus)
                            selection = self.musicsViewModel.idMusicSelected
                        })
                            .font(.system(size: 30))
                            .buttonStyle(.borderless)
                        Button("", systemImage: "playpause.circle", action: {
                            self.musicsViewModel.playPauseSong()
                        })
                        .font(.system(size: 30))
                        .buttonStyle(.borderless)
                        Button("", systemImage: "forward.circle", action: {
                            self.musicsViewModel.navigateSongs(kind: .next)
                            selection = self.musicsViewModel.idMusicSelected
                        })
                            .font(.system(size: 30))
                            .buttonStyle(.borderless)
                        Spacer(minLength: 30)
                        VStack {
                            Slider(value: $musicsViewModel.position, in: 0...self.musicsViewModel.duration)
                                .frame(width: 200, height: 20)
                        Text(verbatim: self.musicsViewModel.isPlaying ? "\(self.musicsViewModel.timePosition) / \(self.musicsViewModel.timeDuration)" : "")
                                .font(.caption2)
                        }
                        
                        Spacer(minLength: 30)
                        Image(nsImage:self.musicsViewModel.getCoverMusic())
                            .resizable()
                            .frame(width: 49, height: 49, alignment: .bottom)
                            .scaledToFit()
                            .aspectRatio(contentMode: .fit)
                            .border(.black)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(verbatim: musicsViewModel.musicSelected.musicTitle)
                                .font(.title3)
                            Text(verbatim: musicsViewModel.musicSelected.artist)
                                .font(.caption2)
                        }
                        
                    }
                }
            }
        }
    }
}

#Preview {
    MusicsView(musicsViewModel: MusicsViewModel())
}
