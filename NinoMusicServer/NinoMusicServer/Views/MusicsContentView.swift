//
//  MusicsContentView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Baptista Machado on 20/01/26.
//

enum MusicContentViewType: Identifiable, CaseIterable, Hashable {
    case musics
    case artists
    case albuns
    
    var id: String {
        switch self {
        case .musics:
            "musics"
        case .artists:
            "artists"
        case .albuns:
            "albuns"
        }
    }
}

import SwiftUI

struct MusicsContentView: View {
    var musicContentViewType: MusicContentViewType
    @ObservedObject var musicPlayerViewModel: MusicPlayerViewModel
    @ObservedObject var musicsViewModel: MusicsViewModel
    @ObservedObject var artistsViewModel: ArtistsViewModel
    @ObservedObject var albunsViewModel: AlbunsViewModel

    var body: some View {
        switch musicContentViewType {
        case .musics:
            MusicsView(musicPlayerViewModel: musicPlayerViewModel, musicsViewModel: musicsViewModel)
                .navigationTitle(String())
        case .artists:
            ArtistsView(musicPlayerViewModel: musicPlayerViewModel, artistsViewModel: artistsViewModel)
                .navigationTitle(String())
        case .albuns:
            AlbunsView(musicPlayerViewModel: musicPlayerViewModel, albunsViewModel: albunsViewModel)
                .navigationTitle(String())
        }
    }
}

#Preview {
    MusicsContentView(musicContentViewType: .musics, musicPlayerViewModel: MusicPlayerViewModel(), musicsViewModel: MusicsViewModel(musicPlayerViewModel: MusicPlayerViewModel()), artistsViewModel: ArtistsViewModel(musicPlayerViewModel: MusicPlayerViewModel()), albunsViewModel: AlbunsViewModel(musicPlayerViewModel: MusicPlayerViewModel()))
}
