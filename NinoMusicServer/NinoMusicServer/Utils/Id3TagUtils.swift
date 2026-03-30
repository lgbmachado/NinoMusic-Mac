//
//  Id3TagUtils.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 02/04/25.
//

import AVFoundation
import Foundation
import ID3TagEditor
import SwiftUI

public class Id3TagUtils {
    
    private let id3TagEditor = ID3TagEditor()
    
    static func getImageCover(path: String) -> NSImage? {
        let id3TagEditor: ID3TagEditor = ID3TagEditor()
        do {
            let id3Tag = try id3TagEditor.read(from: path.removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? "")
            
            if let coverImage = id3Tag?.frames[.attachedPicture(.frontCover)] as? ID3FrameAttachedPicture {
                return NSImage(data: coverImage.picture)
            }
        }
        catch {
            print(error)
        }
        return nil
    }
    
    static func getLyrics(path: String) -> String? {
        let id3TagEditor: ID3TagEditor = ID3TagEditor()
        do {
            let id3Tag = try id3TagEditor.read(from: path.removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? "")
            
            if let frame = id3Tag?.frames[.unsynchronizedLyrics(.unknown)] {
                if let textFrame = frame as? ID3FrameWithStringContent {
                    return textFrame.content
                }
            }
        }
        catch {
            print(error)
        }
        return String()
    }
    
    static func getDuration(url: URL) async -> Int {
        do {
            let audioAsset = AVURLAsset.init(url: url, options: nil)
            let duration = try await audioAsset.load(.duration)
            return ("\(CMTimeGetSeconds(duration))" as NSString).integerValue
        } catch {
            return 0
        }
    }
    
    static func genresAvaiables() -> [String] {
        return ID3Genre.allCases.map { item in
            let rawName = String(describing: item)
            let withSpaces = rawName.replacingOccurrences(
                of: "([a-z0-9])([A-Z])",
                with: "$1 $2",
                options: .regularExpression
            )
            return withSpaces.prefix(1).uppercased() + withSpaces.dropFirst()
        }
    }
    
//    static func saveTags(music: Music, pathCover: URL) throws -> Bool {
//        guard let coverData = try? Data(contentsOf: pathCover) else {
//                    throw NSError(domain: "CoverError", code: 1, userInfo: [
//                        NSLocalizedDescriptionKey: "Não foi possível carregar a imagem da capa"
//                    ])
//                }
//        
//        let frameBuilder = ID32v3TagBuilder()
//            .title(frame: .init(content: music.musicTitle))
//            .album(frame: .init(content: music.album))
//            .artist(frame: .init(content: music.artist))
//            .recordingYear(frame: .init(value: Int(music.year)))
//            .trackPosition(frame: .init(part: music.track, total: 0))
//            .genre(frame: .init(genre: .rock, description: music.genre))
//            .attachedPicture(pictureType: .frontCover, frame: .init(picture: coverData, type: .f, format: <#T##ID3PictureFormat#>))
//            
//                   
//            .attachedPicture(
//                pictureType: .frontCover,
//                description: "Capa do Álbum",
//                data: coverData,
//                type: .jpeg
//            )
//        
//        let tag = frameBuilder.build()
//                .
//                    .title("Nome da Música")
//                    .album("Nome do Álbum")
//                    .artist("Nome do Artista")
//                    .year("2024")
//                    .trackPosition(1, totalTracks: 10)
//                    .genre(.rock)
//                    .attachedPicture(
//                        pictureType: .frontCover,
//                        description: "Capa do Álbum",
//                        data: coverData,
//                        type: .jpeg
//                    )
//
//                let tag = frameBuilder.build()
//
//                try tagEditor.write(tag, to: mp3URL)
//        
//        
//        let id3TagEditor: ID3TagEditor = ID3TagEditor()
//        do {
//            let id3Tag = try id3TagEditor.read(from: music.filePath.removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? "")
//            
//            if let frame = .frames[.unsynchronizedLyrics(.unknown)] {
//                if let textFrame = frame as? ID3FrameWithStringContent {
//                    return textFrame.content
//                }
//            }
//            
//            if let frame = id3Tag?.frames[.unsynchronizedLyrics(.unknown)] {
//                if let textFrame = frame as? ID3FrameWithStringContent {
//                    return textFrame.content
//                }
//            }
//        }
//        catch {
//            print(error)
//        }
//        return String()
//    }
}
