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
                        Section("Biblioteca") {
                            HStack {
                                Image(systemName: "folder")
                                NavigationLink("Diretórios") {
                                    SelectionView(menuSelection: .directories)
                                        .navigationTitle("")
                                }
                            }
                        }
                        Section("Músicas") {
                            HStack {
                                Image(systemName: "music.note.list")
                                NavigationLink("Músicas") {
                                    SelectionView(menuSelection: .musics)
                                        .navigationTitle("")
                                }
                            }
                            
                            HStack {
                                Image(systemName: "mic")
                                NavigationLink("Artistas") {
                                    SelectionView(menuSelection: .artists)
                                        .navigationTitle("")
                                }
                            }
                            
                            HStack {
                                Image(systemName: "opticaldisc")
                                NavigationLink("Álbuns") {
                                    SelectionView(menuSelection: .albuns)
                                        .navigationTitle("")
                                }
                            }
                        }
                        Section("Editor") {
                            HStack {
                                Image(systemName: "tag")
                                NavigationLink("Editor de Tags") {
                                    SelectionView(menuSelection: .tags)
                                        .navigationTitle("")
                                }
                            }
                        }
                        Section("Servidor") {
                            HStack {
                                Image(systemName: "server.rack")
                                NavigationLink("Servidor") {
                                    SelectionView(menuSelection: .server)
                                        .navigationTitle("")
                                }
                            }
                        }
                    }
                    .listStyle(SidebarListStyle())
                    .navigationTitle("Code")
            Text("Nenhuma Opção Selecionada")
                }
    }
}

#Preview {
    ContentView()
}
