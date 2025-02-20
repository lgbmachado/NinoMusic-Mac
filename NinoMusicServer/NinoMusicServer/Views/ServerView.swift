//
//  ServerView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import SwiftUI

struct ServerView: View {
    @Binding var musics: Musics
    
    var body: some View {
        Image(systemName: "server.rack")
            .imageScale(.large)
            .foregroundStyle(.tint)
        Text(String(localized: "text_server").uppercased())
    }
}

#Preview {
    ServerView(musics: .constant(Musics()))
}
