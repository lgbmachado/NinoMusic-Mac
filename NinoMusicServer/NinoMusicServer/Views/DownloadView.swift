//
//  DownloadView.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Baptista Machado on 14/09/26.
//

import SwiftUI
import WebKit

struct DownloadView: View {
    @StateObject var downloadViewModel = DownloadViewModel()
    @State private var searchText = ""
    @State private var selectedVideo: YouTubeItem?
    
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
                                VideoCardView(
                                    video: video,
                                    isDownloading: downloadViewModel.downloadingVideoID == video.id,
                                    onSelect: {
                                    selectedVideo = video
                                    },
                                    onDownload: {
                                        downloadViewModel.downloadMP3(for: video)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 600, minHeight: 400)
        .sheet(item: $selectedVideo) { video in
            YouTubePlayerView(video: video)
        }
        .alert("Download de MP3", isPresented: .init(
            get: { downloadViewModel.downloadMessage != nil },
            set: { isPresented in
                if !isPresented {
                    downloadViewModel.downloadMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {
                downloadViewModel.downloadMessage = nil
            }
        } message: {
            Text(downloadViewModel.downloadMessage ?? "")
        }
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
    let isDownloading: Bool
    let onSelect: () -> Void
    let onDownload: () -> Void
    
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

            Button(action: onDownload) {
                Label(
                    isDownloading ? "Baixando..." : "Baixar MP3",
                    systemImage: isDownloading ? "arrow.down.circle" : "music.note"
                )
            }
            .buttonStyle(.bordered)
            .disabled(isDownloading)
            
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .accessibilityAddTraits(.isButton)
    }
}

private struct YouTubePlayerView: View {
    let video: YouTubeItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(video.snippet.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Button("Abrir no navegador") {
                    openInBrowser()
                }

                Button("Fechar") {
                    dismiss()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            ZStack {
                Color.black

                    YouTubeWebView(videoID: video.id)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(minWidth: 860, minHeight: 530)
    }

    private func openInBrowser() {
        guard let url = URL(string: "https://www.youtube.com/watch?v=\(video.id)") else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}

private struct YouTubeWebView: NSViewRepresentable {
    let videoID: String

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = .audio
        configuration.userContentController.addUserScript(playerOnlyScript)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsMagnification = true
        webView.navigationDelegate = context.coordinator
        webView.load(pageRequest)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard webView.url != pageURL else {
            return
        }

        webView.load(pageRequest)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private var pageRequest: URLRequest {
        URLRequest(url: pageURL)
    }

    private var pageURL: URL {
        var components = URLComponents(string: "https://www.youtube.com/watch")!
        components.queryItems = [URLQueryItem(name: "v", value: videoID)]
        return components.url!
    }

    private var playerOnlyScript: WKUserScript {
        let css = """
        html, body { background: #000 !important; overflow: hidden !important;
        width: 100% !important; height: 100% !important; min-height: 100vh !important; }
        ytd-masthead, #masthead-container, #secondary, #below, ytd-watch-metadata,
        ytd-comments, #comments, #chat, ytd-merch-shelf-renderer,
        ytd-engagement-panel-section-list-renderer { display: none !important; }
        #page-manager, ytd-watch-flexy, #columns, #primary, #player-container,
        #player, #movie_player, .html5-video-container, video {
        width: 100vw !important; height: 100vh !important; min-height: 100vh !important;
        max-width: none !important; margin: 0 !important; padding: 0 !important;
        background: #000 !important; }
        #player { position: fixed !important; inset: 0 !important; }
        video { object-fit: contain !important; }
        .ytp-right-controls { display: none !important; }
        """
        let script = """
        (() => {
            const style = document.createElement('style');
            style.textContent = `\(css)`;
            document.documentElement.appendChild(style);
        })();
        """
        return WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}
