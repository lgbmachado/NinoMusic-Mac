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
    @Published var downloadDirectory: URL {
        didSet {
            UserDefaults.standard.set(downloadDirectory.path, forKey: "DownloadDirectory")
        }
    }
    
    private let apiKey = "AIzaSyAacul_yhlXIduptZzUrVSPBSWfYYTDEUk"
    
    init() {
        let savedDirectory = UserDefaults.standard.string(forKey: "DownloadDirectory")
        if let savedDirectory, !savedDirectory.isEmpty {
            self.downloadDirectory = Self.validatedDirectory(from: URL(fileURLWithPath: savedDirectory, isDirectory: true))
        } else {
            self.downloadDirectory = Self.defaultDownloadDirectory()
        }
    }
    
    func updateDownloadDirectory(_ url: URL) {
        self.downloadDirectory = Self.validatedDirectory(from: url)
    }
    
    private static func defaultDownloadDirectory() -> URL {
        if let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            return downloadsDirectory.appendingPathComponent("NinoMusic", isDirectory: true)
        }
        
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            return documentsDirectory.appendingPathComponent("NinoMusic", isDirectory: true)
        }
        
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads/NinoMusic", isDirectory: true)
    }
    
    private static func validatedDirectory(from url: URL) -> URL {
        let directory = url.standardizedFileURL
        var isDirectory: ObjCBool = false

        if FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory), isDirectory.boolValue {
            if FileManager.default.isWritableFile(atPath: directory.path) {
                return directory
            }
        }

        let fallback = defaultDownloadDirectory()
        do {
            try FileManager.default.createDirectory(at: fallback, withIntermediateDirectories: true)
        } catch {
            return directory
        }

        return fallback
    }
    
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
                outputDirectory = try writableDownloadDirectory()
                ytDlpExecutableURL = try ytDlpURL()
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

        private func writableDownloadDirectory() throws -> URL {
            let directory = DownloadViewModel.validatedDirectory(from: downloadDirectory)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            guard FileManager.default.isWritableFile(atPath: directory.path) else {
                throw DownloadError.destinationReadOnly(directory.path)
            }

            return directory
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
            case destinationReadOnly(String)

            var errorDescription: String? {
                switch self {
                case .missingDirectory:
                    return "Não foi possível localizar a pasta Documents."
                case .missingYTDLP:
                    return "yt-dlp não foi encontrado. Instale yt-dlp e FFmpeg para baixar MP3."
                case .processFailed(let details):
                    return "Falha ao baixar o MP3.\n\(details)"
                case .destinationReadOnly(let path):
                    return "O diretório de destino não é gravável: \(path). Escolha outra pasta de download."
                }
            }
        }

}
