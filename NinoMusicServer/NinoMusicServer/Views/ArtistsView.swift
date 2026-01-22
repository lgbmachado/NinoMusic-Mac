//
//  ArtistsView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 03/09/25.
//

import SwiftUI

// MARK: - Modelo
struct Node: Identifiable {
    var id = UUID()
    let name: String
    var children: [Node]?
}

// MARK: - Artist View
struct ArtistsView: View {
    @ObservedObject var musicPlayerViewModel: MusicPlayerViewModel
    @ObservedObject var artistsViewModel: ArtistsViewModel
    
    @State var selection: Music.ID? = nil
    
    var listData: [Node] {
        var listData = [Node]()
        for artist in artistsViewModel.artists {
            var node = Node(id: artist.id, name: artist.artist)
            node.children = [Node]()
            for album in artist.albuns {
                var subNode = Node(id: album.id ?? UUID(), name: album.album)
                subNode.children = nil
                node.children?.append(subNode)
            }
            listData.append(node)
        }
        return listData
    }
    
    var body: some View {
        List {
            OutlineGroup(listData, children: \.children) { node in
                if node.children == nil {
                    ArtistAlbumView(artistsViewModel: self.artistsViewModel,
                                    musicPlayerViewModel: self.musicPlayerViewModel,
                                    node: node)
                } else {
                    Label(node.name, systemImage: node.children == nil ? "opticaldisc" : "music.microphone")
                }
                
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .navigation) {
                MusicPlayerView(musicsPlayerViewModel: musicPlayerViewModel, selection: $selection)
            }
        }
        .onAppear() {
            artistsViewModel.reloadArtists()
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
        }
    }
    
    private func nextTapped(originNotification: MusicContentViewType?) {
        if originNotification == .artists {
            self.artistsViewModel.navigateSongs(kind: .next)
            self.musicPlayerViewModel.setMusicSelected(music: artistsViewModel.musicSelected)
            self.musicPlayerViewModel.originCurrentMusic = .artists
            self.selection = artistsViewModel.idMusicSelected
        }
    }

    private func previousTapped(originNotification: MusicContentViewType?) {
        if originNotification == .artists {
            self.artistsViewModel.navigateSongs(kind: .previus)
            self.musicPlayerViewModel.setMusicSelected(music: artistsViewModel.musicSelected)
            self.musicPlayerViewModel.originCurrentMusic = .artists
            self.selection = artistsViewModel.idMusicSelected
        }
    }
}

// MARK: - Artist Album View
struct ArtistAlbumView: View {
    @ObservedObject var artistsViewModel: ArtistsViewModel
    @ObservedObject var musicPlayerViewModel: MusicPlayerViewModel

    var node: Node
    var album: ArtistAlbum? {
        for artist in artistsViewModel.artists {
            for album in artist.albuns {
                if album.id == node.id {
                    return album
                }
            }
        }
        return ArtistAlbum.emptyAlbum
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Image(nsImage: Id3TagUtils.getImageCover(path: album?.musics.first?.filePath ?? "") ?? NSImage())
                    .resizable()
                    .frame(width: 75, height: 75, alignment: .bottom)
                    .scaledToFit()
                    .aspectRatio(contentMode: .fit)
                    .border(.black)
                Text(verbatim: album?.album ?? "")
                    .font(.title3)
                Text(verbatim: album?.year ?? "")
                    .font(.caption2)
            }
            .frame(maxWidth: 300, alignment: .leading)
            .padding()
            
            ArtistAlbumMusicView(artistsViewModel: self.artistsViewModel,
                                 musicPlayerViewModel: self.musicPlayerViewModel,
                                 artistSelected: node.name,
                                 albumNameSelected: album?.album ?? "",
                                 albumYearSelected: album?.year ?? "")
        }
    }
}

struct ArtistAlbumMusicView: View {
    @ObservedObject var artistsViewModel: ArtistsViewModel
    @ObservedObject var musicPlayerViewModel: MusicPlayerViewModel
    var artistSelected: String
    var albumNameSelected: String
    var albumYearSelected: String
    @State var selection: ArtistMusic.ID? = nil

    var musics: [ArtistMusic] {
        var result = [ArtistMusic]()
        for artist in artistsViewModel.artists {
            for album in artist.albuns {
                if album.album == albumNameSelected && album.year == albumYearSelected {
                    result = album.musics
                }
            }
        }
        return result
    }
    
    var body: some View {
            Table(musics, selection: $selection) {
                TableColumn(LocalizedStringKey("text_track")) { music in
                    Text("\(music.track)")
                }
                .width(40)
                .alignment(.trailing)
                TableColumn(LocalizedStringKey("text_title"), value: \.musicTitle)
                TableColumn(LocalizedStringKey("text_duration")) { music in
                    Text(String().secondsToTime(seconds: music.duration))
                }
            }
            .onAppear {

            }
            .onChange(of: selection) { oldSelected, newSelected in
                artistsViewModel.setIdSelection(selection: (newSelected ?? UUID()))
                musicPlayerViewModel.setMusicSelected(music: artistsViewModel.musicSelected)
                musicPlayerViewModel.originCurrentMusic = .artists
            }
    }
}

// MARK: - Preview
struct HierarchicalListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ArtistsView(musicPlayerViewModel: MusicPlayerViewModel(), artistsViewModel: ArtistsViewModel())
        }
    }
}
