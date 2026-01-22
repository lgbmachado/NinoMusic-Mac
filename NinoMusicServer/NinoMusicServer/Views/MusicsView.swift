//
//  MusicsView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import SwiftUI

// MARK: MusicsView
struct MusicsView: View {
    @ObservedObject var musicPlayerViewModel: MusicPlayerViewModel
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
                TableColumn(LocalizedStringKey("text_lyric")){ music in
                    if music.hasLyric {
                        Image(systemName: "music.note.tv")
                    }
                }
                .width(50)
            }
            
            .padding()
            .onChange(of: selection) { oldSelected, newSelected in
                self.musicsViewModel.setIdSelection(selection: newSelected ?? UUID())
                self.musicPlayerViewModel.setMusicSelected(music: musicsViewModel.musicSelected)
                self.musicPlayerViewModel.originCurrentMusic = .musics
                proxy.scrollTo(musicsViewModel.idMusicSelected , anchor: .center)
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    MusicPlayerView(musicsPlayerViewModel: musicPlayerViewModel, selection: $selection)
                }
            }
            .onAppear() {
                NotificationCenter.default.addObserver(forName: Notification.Name("nextTapped"),
                                                       object: nil,
                                                       queue: .main) { notification in
                    self.nextTapped(originNotification: notification.userInfo?["origin"] as? MusicContentViewType)
                }
                NotificationCenter.default.addObserver(forName: Notification.Name("previousTapped"),
                                                       object: nil,
                                                       queue: .main) { notification in
                    self.previousTapped(originNotification: notification.userInfo?["origin"] as? MusicContentViewType)
                }
                musicsViewModel.reloadMusics()
            }
            .searchable(text: $searchTerm)
        }
    }
        
    private func nextTapped(originNotification: MusicContentViewType?) {
        if originNotification == .musics {
            self.musicsViewModel.navigateSongs(kind: .next)
            self.musicPlayerViewModel.setMusicSelected(music: musicsViewModel.musicSelected)
            self.musicPlayerViewModel.originCurrentMusic = .musics
            self.selection = musicsViewModel.idMusicSelected
        }
    }

    private func previousTapped(originNotification: MusicContentViewType?) {
        if originNotification == .musics {
            self.musicsViewModel.navigateSongs(kind: .previus)
            self.musicPlayerViewModel.setMusicSelected(music: musicsViewModel.musicSelected)
            self.musicPlayerViewModel.originCurrentMusic = .musics
            self.selection = musicsViewModel.idMusicSelected
        }
    }
    
}

#Preview {
    MusicsView(musicPlayerViewModel: MusicPlayerViewModel(), musicsViewModel: MusicsViewModel())
}
