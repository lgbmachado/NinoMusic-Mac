//
//  ContentView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 05/08/24.
//

import SwiftUI

enum MenuSelection {
    case directories
    case musics
    case artists
    case albuns
    case tags
    case server
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                Section(LocalizedStringKey("text_library")) {
                    HStack {
                        Image(systemName: "folder")
                        NavigationLink(LocalizedStringKey("text_directories")) {
                            SelectionView(menuSelection: .directories)
                                .navigationTitle("")
                        }
                    }
                }
                Section(LocalizedStringKey("text_musics")) {
                    HStack {
                        Image(systemName: "music.note.list")
                        NavigationLink(LocalizedStringKey("text_musics")) {
                            SelectionView(menuSelection: .musics)
                                .navigationTitle("")
                        }
                    }
                    
                    HStack {
                        Image(systemName: "mic")
                        NavigationLink(LocalizedStringKey("text_artists")) {
                            SelectionView(menuSelection: .artists)
                                .navigationTitle("")
                        }
                    }
                    
                    HStack {
                        Image(systemName: "opticaldisc")
                        NavigationLink(LocalizedStringKey("text_albuns")) {
                            SelectionView(menuSelection: .albuns)
                                .navigationTitle("")
                        }
                    }
                }
                Section(LocalizedStringKey("text_editor")) {
                    HStack {
                        Image(systemName: "tag")
                        NavigationLink("Editor de Tags") {
                            SelectionView(menuSelection: .tags)
                                .navigationTitle("")
                        }
                    }
                }
                Section(LocalizedStringKey("text_server")) {
                    HStack {
                        Image(systemName: "server.rack")
                        NavigationLink(LocalizedStringKey("text_music_server")) {
                            SelectionView(menuSelection: .server)
                                .navigationTitle("")
                        }
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("")
            Text(LocalizedStringKey("text_no_option_selected"))
        }
    }
}

#Preview {
    ContentView()
}
