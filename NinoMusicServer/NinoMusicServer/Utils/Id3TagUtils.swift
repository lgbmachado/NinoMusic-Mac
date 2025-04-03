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
}
