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
