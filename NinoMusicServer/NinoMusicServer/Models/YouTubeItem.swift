//
//  YouTubeItem.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Baptista Machado on 14/09/26.
//

struct YouTubeItem: Decodable, Identifiable {
    var id: String { videoIdInfo.videoId }
    let videoIdInfo: VideoId
    let snippet: Snippet
    
    enum CodingKeys: String, CodingKey {
        case videoIdInfo = "id"
        case snippet
    }
}

struct VideoId: Decodable {
    let videoId: String
}

struct Snippet: Decodable {
    let title: String
    let thumbnails: Thumbnails
}

struct Thumbnails: Decodable {
    let medium: ThumbnailDetails
}

struct ThumbnailDetails: Decodable {
    let url: String
}

struct YouTubeSearchResponse: Decodable {
    let items: [YouTubeItem]
}

struct YouTubeErrorResponse: Decodable {
    let error: YouTubeErrorDetail
}

struct YouTubeErrorDetail: Decodable {
    let code: Int
    let message: String
}
