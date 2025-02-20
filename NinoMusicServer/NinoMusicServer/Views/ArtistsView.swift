//
//  ArtistsView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import SwiftUI

struct ArtistsView: View {
    @Binding var musics: Musics
    
    var body: some View {
        VStack {
            Image(systemName: "mic")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(String(localized: "text_artists").uppercased())
        }
    }
}

#Preview {
    ArtistsView(musics: .constant(Musics()))
}
