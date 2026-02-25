//
//  AlbunsView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 01/04/25.
//

import SwiftUI
import ACarousel

struct KeyEventView: NSViewRepresentable {

    var onKeyDown: (NSEvent) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyView()
        view.onKeyDown = onKeyDown
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    class KeyView: NSView {
        var onKeyDown: ((NSEvent) -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            onKeyDown?(event)
        }
    }
}

struct AlbunsView: View {
    @StateObject var musicPlayerViewModel: MusicPlayerViewModel
    @StateObject var albunsViewModel: AlbunsViewModel

    var body: some View {
        VStack {
            ACarousel(albunsViewModel.covers,
                      index: $albunsViewModel.indexAlbumSelected,
                      spacing: 30,
                      headspace: 30,
                      sidesScaling: 1,
                      isWrap: true,
                      autoScroll: .inactive) {  item in
                item.cover?
                    .resizable()
                    .scaledToFill()
                    .frame(width: 250, height: 250, alignment: .bottom)
            }
            
            KeyEventView { event in
                            switch event.keyCode {
                            case 123:
                                albunsViewModel.indexAlbumSelected = max(albunsViewModel.indexAlbumSelected - 1, 0)
                            case 124:
                                albunsViewModel.indexAlbumSelected = min(albunsViewModel.indexAlbumSelected + 1, albunsViewModel.covers.count - 1)
                            default:
                                break
                            }
                        }
            .frame(width: 0, height: 0)

            Text(verbatim: albunsViewModel.albumSelected.album)
                .font(.title)
            Text(verbatim: albunsViewModel.albumSelected.artist)
                .font(.title3)
            Text(verbatim: albunsViewModel.albumSelected.year)
                .font(.caption2)
            Text(verbatim: albunsViewModel.albumSelected.genre)
                .font(.caption2)
            Table(albunsViewModel.albumSelected.musics, selection: $albunsViewModel.idMusicSelected) {
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
            .padding()
            .onChange(of: albunsViewModel.idMusicSelected) { oldSelected, newSelected in
                albunsViewModel.setIdSelection(selection: (newSelected ?? UUID()))
                let music = albunsViewModel.musicSelected
                musicPlayerViewModel.setMusicSelected(music: music)
                musicPlayerViewModel.originCurrentMusic = .albuns
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .navigation) {
                MusicPlayerView(musicsPlayerViewModel: musicPlayerViewModel, selection: $albunsViewModel.idMusicSelected)
            }
        }
    }
}
