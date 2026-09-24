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
    
    private var displayedMusics: [Music] {
        musicsViewModel.filteredMusics(searchTerm: searchTerm)
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            HStack(spacing: 0) {
                Table(displayedMusics, selection: $musicsViewModel.idMusicSelected, sortOrder: $sortOrder) {
                    TableColumn(LocalizedStringKey("text_title"), value: \.musicTitle)
                    TableColumn(LocalizedStringKey("text_artists"), value: \.artist)
                    TableColumn(LocalizedStringKey("text_album"), value: \.album)
                    TableColumn(LocalizedStringKey("text_track")) { music in
                        Text("\(music.track)")
                    }
                    .width(40)
                    .alignment(.trailing)
                    TableColumn(LocalizedStringKey("text_year")) { music in
                        Text("\(music.year)")
                    }
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
                
                AlphabetIndexView(letters: musicsViewModel.availableLetters(in: displayedMusics)) { letter in
                    if let id = musicsViewModel.firstMusicId(forLetter: letter, in: displayedMusics) {
                        proxy.scrollTo(id, anchor: .top)
                    }
                }
            }
            .padding()
            .onChange(of: musicsViewModel.idMusicSelected) { oldSelected, newSelected in
                self.musicsViewModel.setIdSelection(selection: newSelected ?? UUID())
                self.musicPlayerViewModel.setMusicSelected(music: musicsViewModel.musicSelected)
                self.musicPlayerViewModel.originCurrentMusic = .musics
                proxy.scrollTo(musicsViewModel.idMusicSelected , anchor: .center)
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    MusicPlayerView(musicsPlayerViewModel: musicPlayerViewModel, selection: $musicsViewModel.idMusicSelected)
                }
            }
            .searchable(text: $searchTerm)
        }
    }
}

// MARK: - Alphabet Index View
struct AlphabetIndexView: View {
    let letters: [String]
    let onSelect: (String) -> Void
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(letters, id: \.self) { letter in
                Button {
                    onSelect(letter)
                } label: {
                    Text(letter)
                        .font(.caption2.bold())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
    }
}


