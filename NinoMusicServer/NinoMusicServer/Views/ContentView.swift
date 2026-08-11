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
    case tagEditor
    
    var id: String {
        switch self {
        case .musics:
            "musics"
        case .artists:
            "artists"
        case .albuns:
            "tagEditor"
        case .tagEditor:
            "tagEditor"
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
    @State private var showConfig = false
    @State private var showLoadingSheet = false
    @State private var didRunInitialLoad = false
    
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
        .sheet(isPresented: $showLoadingSheet) {
            LoadingViewModelsSheet(
                isMusicsLoading: musicsViewModel.isLoading,
                isArtistsLoading: artistsViewModel.isLoading,
                isAlbunsLoading: albunsViewModel.isLoading,
                isMusicTagLoading: tagEditorViewModel.isLoading
            )
            .interactiveDismissDisabled(showLoadingSheet)
        }
        .task {
            if didRunInitialLoad {
                return
            }
            didRunInitialLoad = true
            showLoadingSheet = true

            _ = await musicsViewModel.reloadMusics()
            _ = await artistsViewModel.reloadArtists()
            _ = await albunsViewModel.reloadAlbuns()
            _ = await tagEditorViewModel.reloadMusics()

            showLoadingSheet = false
        }
        .sheet(isPresented: $showConfig) {
            ConfigurationsView(tagEditorViewModel: tagEditorViewModel,
                               serverViewModel: serverViewModel)
        }
        .toolbar{
            ToolbarItem(placement: .automatic) {
                Button(String(), systemImage: "gear.circle", action: {
                    showConfig = true
                })
            }
        }
    }
}

private struct LoadingViewModelsSheet: View {
    let isMusicsLoading: Bool
    let isArtistsLoading: Bool
    let isAlbunsLoading: Bool
    let isMusicTagLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 10) {
                Image(nsImage: NSImage(named: "NinoMusic") ?? NSImage(named: NSImage.applicationIconName)!)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                Text("Carregando dados")
                    .font(.title)
                    .fontWeight(.semibold)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                loadingRow(title: "Músicas", isLoading: isMusicsLoading)
                loadingRow(title: "Artistas", isLoading: isArtistsLoading)
                loadingRow(title: "Álbuns", isLoading: isAlbunsLoading)
                loadingRow(title: "Tag Editor", isLoading: isMusicTagLoading)
            }
        }
        .padding(28)
        .frame(minWidth: 100)
    }
    
    @ViewBuilder
    private func loadingRow(title: String, isLoading: Bool) -> some View {
        HStack(spacing: 12) {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
                    .tint(.accentColor)
                Text("\(title)")
                    .foregroundStyle(.primary)
                Spacer()
                Text("carregando...")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            } else {
                Image(systemName: "checkmark.circle.fill")
                Text("\(title)")
                    .foregroundStyle(.primary)
                Spacer()
                Text("concluído")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }
}
