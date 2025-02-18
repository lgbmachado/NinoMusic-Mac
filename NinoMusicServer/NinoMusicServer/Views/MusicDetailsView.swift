//
//  MusicDetailsView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 24/01/25.
//

import SwiftUI

struct MusicDetailsView: View {
    var body: some View {
        Image(systemName: "info.circle")
            .imageScale(.large)
            .foregroundStyle(.tint)
        Text("DETALHES DA MÚSICA")
    }
}

#Preview {
    MusicDetailsView()
}
