//
//  DownloadViewModel.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Baptista Machado on 14/09/26.
//


import SwiftUI

class DownloadViewModel: ObservableObject {
    @Published var videos: [YouTubeItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let apiKey = "AIzaSyAacul_yhlXIduptZzUrVSPBSWfYYTDEUk"
    
    func searchVideos(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        
        let urlString = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(encodedQuery)&type=video&videoCategoryId=10&maxResults=20&key=\(apiKey)"

        
        guard let url = URL(string: urlString) else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                if let errorResponse = try? decoder.decode(YouTubeErrorResponse.self, from: data) {
                    self.errorMessage = "Erro ao buscar vídeos: \(errorResponse.error.message)"
                } else {
                    self.errorMessage = "Erro ao buscar vídeos: código HTTP \(httpResponse.statusCode)."
                }
                self.videos = []
                isLoading = false
                return
            }

            let searchResponse = try decoder.decode(YouTubeSearchResponse.self, from: data)
            self.videos = searchResponse.items
        } catch {
            self.errorMessage = "Erro ao buscar vídeos: \(error.localizedDescription)"
            print(error)
        }
        
        isLoading = false
    }
}
