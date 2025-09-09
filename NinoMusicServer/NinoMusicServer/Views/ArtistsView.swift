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

// MARK: - View
struct ArtistsView: View {
    @ObservedObject var artistsViewModel: ArtistsViewModel
    @EnvironmentObject var musicPlayerViewModel: MusicPlayerViewModel
    
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
                    AlbumView(artistsViewModel: self.artistsViewModel,
                              musicPlayerViewModel: musicPlayerViewModel,
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
        }
    }
}

// MARK: ToolbarMusicsView
struct AlbumView: View {
    @ObservedObject var artistsViewModel: ArtistsViewModel
    @ObservedObject var musicPlayerViewModel: MusicPlayerViewModel
    @State var selection: ArtistMusic.ID? = nil
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
    var musics: [ArtistMusic] {
        album?.musics ?? []
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Image(nsImage: Id3TagUtils.getImageCover(path: album?.musics.first?.filePath ?? ""))
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
            
            Table(musics, selection: $selection) {
                TableColumn(LocalizedStringKey("text_track")) { music in
                    Text("\(music.track)")
                }
                .width(40)
                .alignment(.trailing)
                TableColumn(LocalizedStringKey("text_title"), value: \.musicTitle)
                TableColumn("Duração") { music in
                    Text(String().secondsToTime(seconds: music.duration))
                }
            }
            .onChange(of: selection) { oldSelected, newSelected in
                artistsViewModel.setIdSelection(selection: (newSelected ?? UUID()))
                musicPlayerViewModel.setMusicSelected(music: artistsViewModel.musicSelected)
            }
        }
    }
}

// MARK: - Preview
struct HierarchicalListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ArtistsView(artistsViewModel: ArtistsViewModel())
        }
    }
}
