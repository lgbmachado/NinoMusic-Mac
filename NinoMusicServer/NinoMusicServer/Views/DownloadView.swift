//
//  DownloadView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Baptista Machado on 14/09/26.
//

import SwiftUI

struct DownloadView: View {
    @StateObject var downloadViewModel = DownloadViewModel()
    @State private var searchText = ""
    
    // Configuração do mosaico: colunas adaptáveis com largura mínima de 220
    let columns = [
        GridItem(.adaptive(minimum: 220, maximum: 300), spacing: 16)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Barra de Busca superior
            HStack {
                TextField("Pesquisar no YouTube...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        performSearch()
                    }
                
                Button(action: performSearch) {
                    Image(systemName: "magnifyingglass")
                }
                .disabled(downloadViewModel.isLoading)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Área de Conteúdo
            ZStack {
                if downloadViewModel.isLoading {
                    ProgressView("Buscando...")
                } else if let errorMessage = downloadViewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else if downloadViewModel.videos.isEmpty {
                    Text("Nenhum vídeo encontrado. Tente pesquisar algo!")
                        .foregroundColor(.secondary)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(downloadViewModel.videos) { video in
                                VideoCardView(video: video)
                            }
                        }
                        .padding()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 600, minHeight: 400)
    }
    
    private func performSearch() {
        Task {
            await downloadViewModel.searchVideos(query: searchText)
        }
    }
}

// MARK: - Componente do Cartão de Vídeo
struct VideoCardView: View {
    let video: YouTubeItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Carrega a miniatura de forma assíncrona
            AsyncImage(url: URL(string: video.snippet.thumbnails.medium.url)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay(ProgressView())
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(8)
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                @unknown default:
                    EmptyView()
                }
            }
            
            Text(video.snippet.title)
                .font(.headline)
                .lineLimit(2)
                .truncationMode(.tail)
            
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        // Ao clicar no card, abre o vídeo no navegador padrão
        .onTapGesture {
            if let url = URL(string: "https://www.youtube.com/watch?v=\(video.id)") {
                NSWorkspace.shared.open(url)
            }
        }
    }
}
