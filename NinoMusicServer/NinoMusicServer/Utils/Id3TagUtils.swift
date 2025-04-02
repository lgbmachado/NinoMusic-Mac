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
    
    static func getImageCover(path: String) -> NSImage {
        let id3TagEditor: ID3TagEditor = ID3TagEditor()
        do {
            let id3Tag = try id3TagEditor.read(from: path.removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? "")
            
            if let coverImage = id3Tag?.frames[.attachedPicture(.frontCover)] as? ID3FrameAttachedPicture {
                return NSImage(data: coverImage.picture) ?? NSImage()
            }
        }
        catch {
            print(error)
        }
        return NSImage()
    }

    func getTitle(path: String) -> String {
        return self.getString(path: path, frame: .title)
    }
    
    func getArtist(path: String) -> String {
        return self.getString(path: path, frame: .artist)
    }
    
    func getAlbum(path: String) -> String {
        return self.getString(path: path, frame: .album)
    }
    
    func getYear(path: String) -> Int {
        return self.getInt(path: path, frame: .recordingYear)
    }
    
    func getGenre(path: String) -> String {
        return self.getString(path: path, frame: .genre)
    }
    
    func getTrack(path: String) -> Int {
        do {
            let id3Tag = try id3TagEditor.read(from: path.removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? "")
            return ((id3Tag?.frames[.trackPosition] as? ID3FrameWithIntegerContent)?.value ?? Int()) as Int
        }
        catch {
            print(error)
        }
        return Int()
        
//        return self.getInt(path: path, frame: .trackPosition)
    }
    
    func getDuration(path: String) async -> Int {
        if let url = URL(string: path) {
            do {
                let audioAsset = AVURLAsset.init(url: url, options: nil)
                let duration = try await audioAsset.load(.duration)
                return ("\(CMTimeGetSeconds(duration))" as NSString).integerValue
            } catch {
            }
        }
        return 0
    }
    
    private func getString(path: String, frame: FrameName) -> String {
        do {
            let id3Tag = try id3TagEditor.read(from: path.removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? "")
            return ((id3Tag?.frames[frame] as? ID3FrameWithStringContent)?.content ?? String()) as String
        }
        catch {
            print(error)
        }
        return String()
    }
    
    private func getInt(path: String, frame: FrameName) -> Int {
        do {
            let id3Tag = try id3TagEditor.read(from: path.removingPercentEncoding?.replacingOccurrences(of: "file://", with: "") ?? "")
            return ((id3Tag?.frames[frame] as? ID3FrameWithIntegerContent)?.value ?? Int()) as Int
        }
        catch {
            print(error)
        }
        return Int()
    }
}
