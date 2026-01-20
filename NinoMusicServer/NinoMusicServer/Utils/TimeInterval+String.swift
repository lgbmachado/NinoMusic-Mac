//
//  TimeInterval+String.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Baptista Machado on 20/01/26.
//

import Foundation

extension TimeInterval {
    
    func timeIntervalToString() -> String {
        
        var result = ""
        var seconds = Int(self)
        
        var months: Int = 0
        if seconds >= 2592000 {
            months = seconds / 2592000
            if months > 0 {
                result += "\(months) \(months == 1 ? "mês" : "meses") "
            }
            seconds -= months * 2592000
        }
        
        var days: Int = 0
        if seconds >= 86400 {
            days = seconds / 86400
            if days > 0 {
                result += "\(days) \(days == 1 ? "dia" : "dias") "
            }
            seconds -= days * 86400
        }
        
        var hours: Int = 0
        if seconds >= 3600 {
            hours = seconds / 3600
            if hours > 0 {
                result += "\(hours) \(hours == 1 ? "hora" : "horas") "
            }
            seconds -= hours * 3600
        }
        
        var minutes: Int = 0
        if seconds >= 60 {
            minutes = seconds / 60
            if minutes > 0 {
                result += "\(minutes) \(minutes == 1 ? "minuto" : "minutos") "
            }
            seconds -= minutes * 60
        }
        if seconds > 0 {
            result += "e \(seconds) \(seconds == 1 ? "segundo" : "segundos")"
        }
        return result
    }
}


