//
//  ArtistsView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 03/09/25.
//

import SwiftUI

struct ArtistsView: View {
    @ObservedObject var artistsViewModel: ArtistsViewModel
    @State var selection: Music.ID? = nil
    
    var body: some View {
        HStack {
        }
        .onAppear() {
            artistsViewModel.reloadArtists()
        }
    }
    

}

#Preview {
    ArtistsView(artistsViewModel: ArtistsViewModel())
}
