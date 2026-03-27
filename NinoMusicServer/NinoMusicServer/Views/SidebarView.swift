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
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage(named: NSImage.applicationIconName)!)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                Text("Nino Music Server")
                    .font(.title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        
        Divider()
            
        List(selection: $selection) {
            ForEach(ItemMenu.menu) {selection in
                Label(selection.displayName, systemImage: selection.iconName)
                    .tag(selection)
            }
        }
        .padding()
        
    }
}
