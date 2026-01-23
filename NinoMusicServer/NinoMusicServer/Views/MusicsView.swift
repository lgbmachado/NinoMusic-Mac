//
//  MusicsView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import SwiftUI

// MARK: MusicsView
struct MusicsView: View {
    @StateObject var musicPlayerViewModel: MusicPlayerViewModel
    @StateObject var musicsViewModel: MusicsViewModel
    @State private var sortOrder = [KeyPathComparator(\Music.seq)]
    @State private var searchTerm: String = ""
    
    var body: some View {
        ScrollViewReader { proxy in
            Table(musicsViewModel.musics, selection: $musicsViewModel.idMusicSelected, sortOrder: $sortOrder) {
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
                TableColumn(LocalizedStringKey("text_lyric")){ music in
                    if music.hasLyric {
                        Image(systemName: "music.note.tv")
                    }
                }
                .width(50)
            }
            
            .padding()
            .onChange(of: musicsViewModel.idMusicSelected) { oldSelected, newSelected in
                self.musicsViewModel.setIdSelection(originNotification: .musics, selection: newSelected ?? UUID())
                self.musicPlayerViewModel.setMusicSelected(music: musicsViewModel.musicSelected)
                self.musicPlayerViewModel.originCurrentMusic = .musics
                proxy.scrollTo(musicsViewModel.idMusicSelected , anchor: .center)
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    MusicPlayerView(musicsPlayerViewModel: musicPlayerViewModel, selection: $musicsViewModel.idMusicSelected)
                }
            }
            .onAppear() {
                musicsViewModel.reloadMusics()
            }
            .searchable(text: $searchTerm)
        }
    }
}

#Preview {
    MusicsView(musicPlayerViewModel: MusicPlayerViewModel(), musicsViewModel: MusicsViewModel(musicPlayerViewModel: MusicPlayerViewModel()))
}

