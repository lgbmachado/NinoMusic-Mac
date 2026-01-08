//
//  LyricView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Baptista Machado on 07/01/26.
//

import SwiftUI

struct LyricView: View {
    var lyricText: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            ScrollView {
                Text(lyricText)
                    .lineLimit(nil)
                    .padding()
            }
            Button(LocalizedStringKey("text_close")) {
                dismiss()
            }
        }
        .frame(width: 400, height: 600, alignment: .init(horizontal: .center, vertical: .center))
        .padding()
    }
}
