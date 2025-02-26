//
//  SidebarView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 25/02/25.
//

import SwiftUI

struct SidebarView: View {
    @Binding var selection: ItemMenu
    
    var body: some View {
        List(selection: $selection) {
            ForEach(ItemMenu.menu) {selection in
                Label(selection.displayName, systemImage: selection.iconName)
                    .tag(selection)
            }
        }
        .padding()
        
    }
}

#Preview {
    SidebarView(selection: .constant(.musics))
}
