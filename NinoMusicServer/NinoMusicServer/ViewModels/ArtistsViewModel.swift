//
//  ArtistsViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 03/09/25.
//

import Foundation
import ID3TagEditor
import SwiftUI

class ArtistsViewModel: NSObject, ObservableObject {
    
    @Published var artist: [Artist] = []
    @Published var artistSelected: Artist = Artist.emptyArtist
    @Published var idArtistSelected: Artist.ID = UUID()
    @Published var idAlbumSelected: ArtistAlbum.ID = UUID()
    @Published var idMusicSelected: ArtistMusic.ID = UUID()
    @Published var fileSelected: String = String()
    @Published var musicSelected: ArtistMusic = ArtistMusic.emptyMusic
    
    func reloadArtists() {
        self.artist = MusicFiles().artists
        self.artistSelected = artist.first ?? Artist.emptyArtist
        self.idArtistSelected = artistSelected.id
    }
}
