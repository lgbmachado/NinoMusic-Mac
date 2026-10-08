//
//  ArtistsView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 03/09/25.
//

import SwiftUI

// MARK: - Artist View
struct ArtistsView: View {
    @ObservedObject var musicPlayerViewModel: MusicPlayerViewModel
    @ObservedObject var artistsViewModel: ArtistsViewModel
    
    @State var selection: UUID? = nil
    @State private var expandedArtists: Set<UUID> = []
        
    var body: some View {
        List {
            ForEach(artistsViewModel.getGroupedNodes(), id: \.letter) { group in
                Section(header: Text(group.letter)
                    .font(.largeTitle)) {
                    ForEach(group.nodes) { node in
                        Button {
                            if expandedArtists.contains(node.id) {
                                expandedArtists.remove(node.id)
                            } else {
                                expandedArtists.insert(node.id)
                            }
                        } label: {
                            HStack {
                                Image(systemName: expandedArtists.contains(node.id) ? "chevron.down" : "chevron.right")
                                    .frame(width: 12)
                                Label(node.name, systemImage: "music.microphone")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if expandedArtists.contains(node.id) {
                            ForEach(node.children ?? []) { albumNode in
                                ArtistAlbumView(artistsViewModel: self.artistsViewModel,
                                                musicPlayerViewModel: self.musicPlayerViewModel,
                                                node: albumNode)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .onChange(of: artistsViewModel.idMusicSelected) { _, newSelected in
            guard let newSelected else {
                return
            }
            artistsViewModel.setIdSelection(selection: newSelected)
            musicPlayerViewModel.setMusicSelected(music: artistsViewModel.musicSelected)
            musicPlayerViewModel.originCurrentMusic = .artists
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                MusicPlayerView(musicsPlayerViewModel: musicPlayerViewModel, selection: $selection)
            }
        }
    }
}

// MARK: - Artist Album View
struct ArtistAlbumView: View {
    @ObservedObject var artistsViewModel: ArtistsViewModel
    @ObservedObject var musicPlayerViewModel: MusicPlayerViewModel

    var node: Node
    @State private var coverImage: NSImage?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Image(nsImage: coverImage ?? NSImage())
                    .resizable()
                    .frame(width: 75, height: 75, alignment: .bottom)
                    .scaledToFit()
                    .aspectRatio(contentMode: .fit)
                    .border(.black)
                Text(verbatim: node.album?.album ?? "")
                    .font(.title3)
                Text(verbatim: String(node.album?.year ?? 0))
                    .font(.caption2)
            }
            .frame(maxWidth: 200, alignment: .leading)
            .padding()
            
            ArtistAlbumMusicView(artistsViewModel: self.artistsViewModel,
                                 musicPlayerViewModel: self.musicPlayerViewModel,
                                 musics: node.album?.musics ?? [ArtistMusic]())
        }
        .task(id: node.album?.musics.first?.filePath) {
            coverImage = nil
            guard let path = node.album?.musics.first?.filePath, !path.isEmpty else {
                return
            }
            let image = await withCheckedContinuation { (continuation: CheckedContinuation<NSImage?, Never>) in
                DispatchQueue.global(qos: .utility).async {
                    continuation.resume(returning: Id3TagUtils.getImageCover(path: path, maxPixelSize: 150))
                }
            }
            guard !Task.isCancelled else {
                return
            }
            coverImage = image
        }
    }
}

struct ArtistAlbumMusicView: View {
    @ObservedObject var artistsViewModel: ArtistsViewModel
    @ObservedObject var musicPlayerViewModel: MusicPlayerViewModel
    var musics: [ArtistMusic]
    
    var body: some View {
            Table(musics, selection: $artistsViewModel.idMusicSelected) {
                TableColumn(LocalizedStringKey("text_favorite")) { music in
                    Button {
                        artistsViewModel.toggleFavorite(music: music)
                    } label: {
                        Image(systemName: music.isFavorite ? "star.fill" : "star")
                            .foregroundStyle(music.isFavorite ? Color.yellow : Color.secondary.opacity(0.3))
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .width(50)
                TableColumn(LocalizedStringKey("text_track")) { music in
                    Text("\(music.track)")
                }
                .width(40)
                .alignment(.trailing)
                TableColumn(LocalizedStringKey("text_title"), value: \.musicTitle)
                TableColumn(LocalizedStringKey("text_duration")) { music in
                    Text(String().secondsToTime(seconds: music.duration))
                }
                .width(100)
                TableColumn(LocalizedStringKey("text_lyric")){ music in
                    if music.hasLyric {
                        Image(systemName: "music.note.tv")
                    }
                }
                .width(40)
                TableColumn(LocalizedStringKey("text_last_update")) { music in
                    Text(music.lastUpdate.formatted(date: .numeric, time: .shortened))
                }
                .width(120)
                TableColumn(LocalizedStringKey("text_last_execution")) { music in
                    // LastExecution is stored as -1 when the music was never played
                    if music.lastExecution.timeIntervalSince1970 >= 0 {
                        Text(music.lastExecution.formatted(date: .numeric, time: .shortened))
                    }
                }
                .width(120)
                TableColumn(LocalizedStringKey("text_count_execution")) { music in
                    Text("\(music.countExecution)")
                }
                .width(65)
                .alignment(.trailing)
            }
            .frame(height: min(420, max(180, CGFloat(musics.count) * 28 + 36)))
    }
}
