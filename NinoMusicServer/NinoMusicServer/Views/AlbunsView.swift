//
//  AlbunsView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import SwiftUI

struct AlbunsView: View {
    @Binding var musics: Musics
    
    var body: some View {
        VStack {
            VStack {
                Image(systemName: "opticaldisc")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text(String(localized: "text_albuns").uppercased())
            }
        }
    }
}

#Preview {
    AlbunsView(musics: .constant(Musics()))
}
