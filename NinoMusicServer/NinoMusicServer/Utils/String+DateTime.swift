//
//  String+DateTime.swift
//  NinoMusic
//
//  Created by Luiz Guilherme Machado on 04/10/23.
//

import Foundation

extension String {
    
    func secondsToTime(seconds: Int) -> String {
        let hour = Int(seconds) / 3600
        let minute = Int(seconds) / 60 % 60
        let second = Int(seconds) % 60

        return hour > 0 ? String(format: "%02i:%02i:%02i", hour, minute, second) : String(format: "%02i:%02i", minute, second)
    }
    
}

