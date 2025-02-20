//
//  TagFieldsView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 27/01/25.
//

import SwiftUI

struct TagFieldsView: View {
    var body: some View {
        HStack {
            Image(.discCover)
                .resizable()
                .frame(width: 300, height: 300, alignment: .bottom)
                .scaledToFit()
                .aspectRatio(contentMode: .fit)
                .border(.black)
            VStack {
                Text(LocalizedStringKey("text_album"))
                TextField(LocalizedStringKey("text_album_name"), text: .constant(""))
                Text(LocalizedStringKey("text_artit"))
                TextField(LocalizedStringKey("text_artit_name"), text: .constant(""))
            }
        }
    }
}

#Preview {
    TagFieldsView()
}
