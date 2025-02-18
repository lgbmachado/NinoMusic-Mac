//
//  NSData+Sufix.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Machado on 14/10/22.
//

import Foundation

extension Data {
    func hasSuffix(_ bytes: UInt8...) -> Bool {
        if self.count < bytes.count { return false }
        for (i, byte) in bytes.enumerated() {
            if self[self.count - bytes.count + i] != byte {
                return false
            }
        }
        return true
    }
}
