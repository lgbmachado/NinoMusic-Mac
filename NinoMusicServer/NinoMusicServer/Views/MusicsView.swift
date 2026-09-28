//
//  MusicsView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: MusicsView
struct MusicsView: View {
    @StateObject var musicPlayerViewModel: MusicPlayerViewModel
    @StateObject var musicsViewModel: MusicsViewModel
    @State private var sortOrder = [KeyPathComparator(\Music.seq)]
    @State private var searchTerm: String = ""
    @State private var showExportResult = false
    @State private var exportSucceeded = false
    
    private var displayedMusics: [Music] {
        musicsViewModel.filteredMusics(searchTerm: searchTerm)
    }
    
    @TableColumnBuilder<Music, KeyPathComparator<Music>>
    private var infoColumns: some TableColumnContent<Music, KeyPathComparator<Music>> {
        TableColumn(LocalizedStringKey("text_favorite")) { (music: Music) in
            Button {
                musicsViewModel.toggleFavorite(music: music)
            } label: {
                Image(systemName: music.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(music.isFavorite ? Color.yellow : Color.secondary.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .width(50)
        TableColumn(LocalizedStringKey("text_title"), value: \Music.musicTitle)
        TableColumn(LocalizedStringKey("text_artists"), value: \Music.artist)
        TableColumn(LocalizedStringKey("text_album"), value: \Music.album)
        TableColumn(LocalizedStringKey("text_track")) { (music: Music) in
            Text("\(music.track)")
        }
        .width(40)
        .alignment(.trailing)
        TableColumn(LocalizedStringKey("text_year")) { (music: Music) in
            Text("\(music.year)")
        }
        .width(50)
        TableColumn(LocalizedStringKey("text_genre"), value: \Music.genre)
            .width(100)
        TableColumn(LocalizedStringKey("text_lyric")) { (music: Music) in
            if music.hasLyric {
                Image(systemName: "music.note.tv")
            }
        }
        .width(50)
    }
    
    @TableColumnBuilder<Music, KeyPathComparator<Music>>
    private var executionColumns: some TableColumnContent<Music, KeyPathComparator<Music>> {
        TableColumn(LocalizedStringKey("text_last_update")) { (music: Music) in
            Text(music.lastUpdate.formatted(date: .numeric, time: .shortened))
        }
        .width(120)
        TableColumn(LocalizedStringKey("text_last_execution")) { (music: Music) in
            // LastExecution is stored as -1 when the music was never played
            if music.lastExecution.timeIntervalSince1970 >= 0 {
                Text(music.lastExecution.formatted(date: .numeric, time: .shortened))
            }
        }
        .width(120)
        TableColumn(LocalizedStringKey("text_count_execution")) { (music: Music) in
            Text("\(music.countExecution)")
        }
        .width(70)
        .alignment(.trailing)
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            HStack(spacing: 0) {
                Table(displayedMusics, selection: $musicsViewModel.idMusicSelected, sortOrder: $sortOrder) {
                    infoColumns
                    executionColumns
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
                ToolbarItem(placement: .primaryAction) {
                    Button(LocalizedStringKey("text_export_favorites"), systemImage: "star.square.on.square") {
                        exportFavorites()
                    }
                    .help(LocalizedStringKey("text_export_favorites"))
                    .disabled(!musicsViewModel.hasFavorites)
                }
            }
            .alert(LocalizedStringKey(exportSucceeded ? "text_export_favorites_success" : "text_export_favorites_error"),
                   isPresented: $showExportResult) {
                Button("OK", role: .cancel) { }
            }
            .searchable(text: $searchTerm)
        }
    }
    
    private func exportFavorites() {
        let dialog = NSSavePanel()
        dialog.allowedContentTypes = [.m3uPlaylist]
        dialog.nameFieldStringValue = "Favoritas.m3u"
        if dialog.runModal() == .OK, let url = dialog.url {
            exportSucceeded = musicsViewModel.exportFavoritesToM3U(url: url)
            showExportResult = true
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


