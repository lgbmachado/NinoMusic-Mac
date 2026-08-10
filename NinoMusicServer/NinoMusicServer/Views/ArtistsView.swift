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
        
    var body: some View {
        List {
            OutlineGroup(artistsViewModel.getNodes(), children: \.children) { node in
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
                Text(verbatim: String(album?.year ?? 0))
                    .font(.caption2)
            }
            .frame(maxWidth: 300, alignment: .leading)
            .padding()
            
            ArtistAlbumMusicView(artistsViewModel: self.artistsViewModel,
                                 musicPlayerViewModel: self.musicPlayerViewModel,
                                 musics: node.musics ?? [ArtistMusic]())
        }
    }
}

struct ArtistAlbumMusicView: View {
    @ObservedObject var artistsViewModel: ArtistsViewModel
    @ObservedObject var musicPlayerViewModel: MusicPlayerViewModel
    var musics: [ArtistMusic]
    
    var body: some View {
            Table(musics, selection: $artistsViewModel.idMusicSelected) {
                TableColumn(LocalizedStringKey("text_track")) { music in
                    Text("\(music.track)")
                }
                .width(40)
                .alignment(.trailing)
                TableColumn(LocalizedStringKey("text_title"), value: \.musicTitle)
                TableColumn(LocalizedStringKey("text_duration")) { music in
                    Text(String().secondsToTime(seconds: music.duration))
                }
                TableColumn(LocalizedStringKey("text_lyric")){ music in
                    if music.hasLyric {
                        Image(systemName: "music.note.tv")
                    }
                }
            }
            .onAppear {

            }
            .onChange(of: artistsViewModel.idMusicSelected) { oldSelected, newSelected in
                artistsViewModel.setIdSelection(selection: (newSelected ?? UUID()))
                musicPlayerViewModel.setMusicSelected(music: artistsViewModel.musicSelected)
                musicPlayerViewModel.originCurrentMusic = .artists
            }
    }
}
