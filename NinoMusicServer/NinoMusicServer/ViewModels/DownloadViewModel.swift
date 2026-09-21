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
    @Published var downloadingVideoID: String?
    @Published var downloadMessage: String?
    
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

        func downloadMP3(for video: YouTubeItem) {
            guard downloadingVideoID == nil else { return }

            downloadingVideoID = video.id
            downloadMessage = nil

            let outputDirectory: URL
            let ytDlpExecutableURL: URL
            do {
                outputDirectory = try downloadDirectory()
                ytDlpExecutableURL = try ytDlpURL()
                try FileManager.default.createDirectory(at: outputDirectory,
                                                         withIntermediateDirectories: true)
            } catch {
                downloadingVideoID = nil
                downloadMessage = error.localizedDescription
                return
            }

            let videoID = video.id
            Task.detached { [weak self] in
                do {
                    let process = Process()
                    process.executableURL = ytDlpExecutableURL
                    process.arguments = [
                        "--no-playlist",
                        "--extract-audio",
                        "--audio-format", "mp3",
                        "--audio-quality", "0",
                        "--output", outputDirectory.appendingPathComponent("%(title)s.%(ext)s").path,
                        "https://www.youtube.com/watch?v=\(videoID)"
                    ]
                    process.environment = [
                        "PATH": "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
                    ]

                    let errorPipe = Pipe()
                    process.standardError = errorPipe
                    process.standardOutput = Pipe()
                    try process.run()
                    process.waitUntilExit()

                    guard process.terminationStatus == 0 else {
                        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                        let details = String(data: errorData, encoding: .utf8)?
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        throw DownloadError.processFailed(details ?? "O yt-dlp terminou com erro.")
                    }

                    await MainActor.run {
                        self?.downloadingVideoID = nil
                        self?.downloadMessage = "MP3 salvo em: \(outputDirectory.path)"
                    }
                } catch {
                    await MainActor.run {
                        self?.downloadingVideoID = nil
                        self?.downloadMessage = error.localizedDescription
                    }
                }
            }
        }

        private func downloadDirectory() throws -> URL {
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory,
                                                                      in: .userDomainMask).first else {
                throw DownloadError.missingDirectory
            }

            return documentsDirectory.appendingPathComponent("download", isDirectory: true)
        }

        private func ytDlpURL() throws -> URL {
            let candidates = [
                "/opt/homebrew/bin/yt-dlp",
                "/usr/local/bin/yt-dlp",
                "/usr/bin/yt-dlp"
            ]

            if let executablePath = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
                return URL(fileURLWithPath: executablePath)
            }

            throw DownloadError.missingYTDLP
        }

        private enum DownloadError: LocalizedError {
            case missingDirectory
            case missingYTDLP
            case processFailed(String)

            var errorDescription: String? {
                switch self {
                case .missingDirectory:
                    return "Não foi possível localizar a pasta Documents."
                case .missingYTDLP:
                    return "yt-dlp não foi encontrado. Instale yt-dlp e FFmpeg para baixar MP3."
                case .processFailed(let details):
                    return "Falha ao baixar o MP3.\n\(details)"
                }
            }
        }

}
