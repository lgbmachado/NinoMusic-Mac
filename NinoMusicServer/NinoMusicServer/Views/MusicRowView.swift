//
//  MusicRowView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 08/08/24.
//

import SwiftUI

struct MusicRowView: View {
    
    @State var music: Music
    
    var body: some View {
        GridRow {
            Text(music.musicTitle)
                .bold()
            Text(music.artist)
            Text(music.album)
            Text(String(format: "%d", music.track))
                .gridColumnAlignment(.trailing)
            Text(music.year)
            Text(music.genre)
        }
    }
}

#Preview {
    MusicRowView(music: Music.example)
}
