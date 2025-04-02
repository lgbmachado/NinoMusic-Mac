//
//  Id3TagUtils.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 02/04/25.
//

import Foundation
import ID3TagEditor
import SwiftUI

public class Id3TagUtils {
    
    static func getImageCover(path: String) -> NSImage {
        let id3TagEditor: ID3TagEditor = ID3TagEditor()
        do {
            let id3Tag = try id3TagEditor.read(from: path.replacingOccurrences(of: "file://", with: "").replacingOccurrences(of: "%20", with: " "))
            
            if let coverImage = id3Tag?.frames[.attachedPicture(.frontCover)] as? ID3FrameAttachedPicture {
                return NSImage(data: coverImage.picture) ?? NSImage()
            }
        }
        catch {
            print(error)
        }
        return NSImage()
    }
        
    static func getArtist(path: String) -> String {
        return self.getString(path: path, frame: .artist)
    }
    
    static func getYear(path: String) -> String {
        return self.getInt(path: path, frame: .recordingYear)
    }
    
    private static func getString(path: String, frame: FrameName) -> String {
        let id3TagEditor: ID3TagEditor = ID3TagEditor()
        do {
            let id3Tag = try id3TagEditor.read(from: path.replacingOccurrences(of: "file://", with: "").replacingOccurrences(of: "%20", with: " "))
            
            return ((id3Tag?.frames[frame] as? ID3FrameWithStringContent)?.content ?? String()) as String
        }
        catch {
            print(error)
        }
        return String()
    }
    
    private static func getInt(path: String, frame: FrameName) -> Int {
        let id3TagEditor: ID3TagEditor = ID3TagEditor()
        do {
            let id3Tag = try id3TagEditor.read(from: path.replacingOccurrences(of: "file://", with: "").replacingOccurrences(of: "%20", with: " "))
            
            return ((id3Tag?.frames[.recordingYear] as? ID3FrameWithIntegerContent)?.value ?? Int()) as Int
        }
        catch {
            print(error)
        }
        return Int()
    }
    
    

    
    
//    let album = ((id3Tag?.frames[ .album] as? ID3FrameWithStringContent)?.content ?? String()) as String
//    let year = ((id3Tag?.frames[.recordingYear] as? ID3FrameWithIntegerContent)?.value ?? Int()) as Int
//    let track = ((id3Tag?.frames[.trackPosition] as? ID3FramePartOfTotal)?.part ?? Int()) as Int
//    let duration = await getDuration(url: fileURL)
//    let musicTitle = ((id3Tag?.frames[.title] as? ID3FrameWithStringContent)?.content ?? String()) as String
//    let genre = ((id3Tag?.frames[.genre] as? ID3FrameGenre)?.description ?? String()) as String
}
