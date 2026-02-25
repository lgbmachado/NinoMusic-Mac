//
//  ContentView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 24/02/25.
//

import SwiftUI

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

struct ContentView: View {
    @ObservedObject var musicPlayerViewModel: MusicPlayerViewModel
    
    @ObservedObject var libraryViewModel: LibraryViewModel
    @ObservedObject var musicsViewModel: MusicsViewModel
    @ObservedObject var tagEditorViewModel: TagEditorViewModel
    @ObservedObject var artistsViewModel: ArtistsViewModel
    @ObservedObject var albunsViewModel: AlbunsViewModel
    @ObservedObject var serverViewModel: ServerViewModel
    
    @State private var selection: ItemMenu = .musics

    private var isLoadingData: Bool {
        musicsViewModel.isLoading || artistsViewModel.isLoading || albunsViewModel.isLoading
    }

    private var loadingSheetBinding: Binding<Bool> {
        Binding(get: { isLoadingData }, set: { _ in })
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
        } detail: {
            switch selection {
            case .libray:
                LibraryView(musicsViewModel: musicsViewModel, libraryViewModel: libraryViewModel)
                    .navigationTitle(String())
            case .musics:
                MusicsView(musicPlayerViewModel: musicPlayerViewModel, musicsViewModel: musicsViewModel)
                    .navigationTitle(String())
            case .artists:
                ArtistsView(musicPlayerViewModel: musicPlayerViewModel, artistsViewModel: artistsViewModel)
                    .navigationTitle(String())
            case .albuns:
                AlbunsView(musicPlayerViewModel: musicPlayerViewModel, albunsViewModel: albunsViewModel)
                    .navigationTitle(String())
            case .tags:
                TagEditorView(tagEditorViewModel: tagEditorViewModel)
                    .navigationTitle(String())
            case .server:
                ServerView(serverViewModel: serverViewModel)
                    .navigationTitle(String())
            }
        }
        .sheet(isPresented: loadingSheetBinding) {
            LoadingViewModelsSheet(
                isMusicsLoading: musicsViewModel.isLoading,
                isArtistsLoading: artistsViewModel.isLoading,
                isAlbunsLoading: albunsViewModel.isLoading
            )
            .interactiveDismissDisabled(isLoadingData)
        }
        .task {
            async let musicsTask = musicsViewModel.reloadMusics()
            async let artistsTask = artistsViewModel.reloadArtists()
            async let albunsTask = albunsViewModel.reloadAlbuns()
            _ = await (musicsTask, artistsTask, albunsTask)
            albunsViewModel.indexAlbumSelected = 0
        }
    }
}

private struct LoadingViewModelsSheet: View {
    let isMusicsLoading: Bool
    let isArtistsLoading: Bool
    let isAlbunsLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Carregando dados")
                .font(.title3)
                .fontWeight(.semibold)

            loadingRow(title: "Músicas", isLoading: isMusicsLoading)
            loadingRow(title: "Artistas", isLoading: isArtistsLoading)
            loadingRow(title: "Álbuns", isLoading: isAlbunsLoading)
        }
        .padding(24)
        .frame(minWidth: 320)
    }

    @ViewBuilder
    private func loadingRow(title: String, isLoading: Bool) -> some View {
        HStack(spacing: 10) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                Text("\(title): carregando...")
            } else {
                Image(systemName: "checkmark.circle.fill")
                Text("\(title): concluído")
            }
        }
    }
}
