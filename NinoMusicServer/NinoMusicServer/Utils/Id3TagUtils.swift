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
    private static let coverCache = NSCache<NSString, NSImage>()
    
    private let id3TagEditor = ID3TagEditor()
    
    static func getImageCover(path: String, maxPixelSize: CGFloat? = nil) -> NSImage? {
        let normalizedPath = path.removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? ""
        guard !normalizedPath.isEmpty else {
            return nil
        }

        let cacheKey = "\(normalizedPath)|\(maxPixelSize.map { String(Int($0)) } ?? "original")" as NSString
        if let cachedImage = coverCache.object(forKey: cacheKey) {
            return cachedImage
        }

        let id3TagEditor: ID3TagEditor = ID3TagEditor()
        do {
            let id3Tag = try id3TagEditor.read(from: normalizedPath)
            
            if let coverImage = id3Tag?.frames[.attachedPicture(.frontCover)] as? ID3FrameAttachedPicture {
                guard let image = NSImage(data: coverImage.picture) else {
                    return nil
                }

                let finalImage = maxPixelSize.map { image.resized(maxPixelSize: $0) } ?? image
                coverCache.setObject(finalImage, forKey: cacheKey)
                return finalImage
            }
        }
        catch {
            print(error)
        }
        return nil
    }
    
    static func getLyrics(path: String) -> String? {
        let normalizedPath = path.removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? path
        guard !normalizedPath.isEmpty else {
            return String()
        }

        let id3TagEditor: ID3TagEditor = ID3TagEditor()
        do {
            let id3Tag = try id3TagEditor.read(from: normalizedPath)
            return lyrics(in: id3Tag) ?? String()
        } catch {
            print(error)
            return String()
        }
    }

    static func hasLyrics(path: String) -> Bool {
        let lyric = getLyrics(path: path)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !lyric.isEmpty
    }

    static func lyrics(in id3Tag: ID3Tag?) -> String? {
        guard let id3Tag else {
            return nil
        }

        func nonEmptyContent(in frame: ID3Frame) -> String? {
            let content: String?
            if let localizedFrame = frame as? ID3FrameWithLocalizedContent {
                content = localizedFrame.content
            } else {
                content = (frame as? ID3FrameWithStringContent)?.content
            }

            guard let content,
                  !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            return content
        }

        for (frameName, frame) in id3Tag.frames {
            guard case .unsynchronizedLyrics = frameName else {
                continue
            }
            if let content = nonEmptyContent(in: frame) {
                return content
            }
        }

        for (frameName, frame) in id3Tag.frames {
            guard case .comment = frameName else {
                continue
            }
            if let content = nonEmptyContent(in: frame) {
                return content
            }
        }

        return nil
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
}

private extension NSImage {
    func resized(maxPixelSize: CGFloat) -> NSImage {
        guard size.width > 0, size.height > 0 else {
            return self
        }

        let scale = min(maxPixelSize / size.width, maxPixelSize / size.height, 1)
        guard scale < 1 else {
            return self
        }

        let newSize = NSSize(width: size.width * scale, height: size.height * scale)
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        draw(in: NSRect(origin: .zero, size: newSize),
             from: NSRect(origin: .zero, size: size),
             operation: .copy,
             fraction: 1)
        resizedImage.unlockFocus()
        return resizedImage
    }
}
