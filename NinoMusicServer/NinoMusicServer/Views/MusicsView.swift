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
    
    @State private var sortOrder = [KeyPathComparator(\Music.seq)]
    @State private var searchTerm: String = ""
    @State var selection: Music.ID? = nil
    
    var tableData: [Music] {
        if searchTerm.isEmpty {
            return musicsViewModel.musics.sorted(using: sortOrder)
        } else {
            return musicsViewModel.musics
                .filter { $0.musicTitle.lowercased().contains(searchTerm.lowercased()) ||
                    $0.artist.lowercased().contains(searchTerm.lowercased()) ||
                    $0.album.lowercased().contains(searchTerm.lowercased()) ||
                    $0.genre.lowercased().contains(searchTerm.lowercased())}
                .sorted(using: sortOrder)
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            Table(tableData, selection: $selection, sortOrder: $sortOrder) {
                TableColumn(LocalizedStringKey("text_title"), value: \.musicTitle)
                TableColumn(LocalizedStringKey("text_artists"), value: \.artist)
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
                proxy.scrollTo(musicsViewModel.idMusicSelected , anchor: .center)
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    ToolbarMusicsView(musicsViewModel: musicsViewModel, selection: $selection)
                }
            }
            .onAppear() {
                musicsViewModel.reloadMusics()
            }
            .searchable(text: $searchTerm)
        }
    }
}

// MARK: ToolbarMusicsView
struct ToolbarMusicsView: View {
    @ObservedObject var musicsViewModel: MusicsViewModel
    @Binding var selection: Music.ID?
    
    @State private var isMovingSlider = false
    @State var dragGestureValue: DragGesture.Value?
    
    var body: some View {
        
        VStack {
            HStack {
                Button(String(), systemImage: "backward.circle", action: {
                    self.musicsViewModel.navigateSongs(kind: .previus)
                    selection = self.musicsViewModel.idMusicSelected
                })
                .font(.system(size: 30))
                .buttonStyle(.borderless)
                Button(String(), systemImage: "playpause.circle", action: {
                    self.musicsViewModel.playPauseSong()
                })
                .font(.system(size: 30))
                .buttonStyle(.borderless)
                Button(String(), systemImage: "forward.circle", action: {
                    self.musicsViewModel.navigateSongs(kind: .next)
                    selection = self.musicsViewModel.idMusicSelected
                })
                .font(.system(size: 30))
                .buttonStyle(.borderless)
                Spacer(minLength: 30)
                VStack {
                    Slider(value: $musicsViewModel.position, in: 0...self.musicsViewModel.duration, onEditingChanged: { editing in
                        isMovingSlider = editing
                        if !isMovingSlider {
                            self.musicsViewModel.setMusicPosition(newPosition: musicsViewModel.position)
                        }
                    })
                        .frame(width: 200, height: 20)
                    Text(verbatim: self.musicsViewModel.isPlaying ? "\(self.musicsViewModel.timePosition) / \(self.musicsViewModel.timeDuration)" : "00:00 / 00:00")
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


#Preview {
    MusicsView(musicsViewModel: MusicsViewModel())
}
