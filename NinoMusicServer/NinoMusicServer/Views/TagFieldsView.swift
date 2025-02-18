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
                Text("Album")
                TextField("Album Name", text: .constant(""))
                Text("Artist")
                TextField("Artist Name", text: .constant(""))
            }
        }
    }
}

#Preview {
    TagFieldsView()
}
