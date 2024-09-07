//
//  Formatter.swift
//  Tauch
//
//  Created by Musa Yazuju on 2022/05/16.
//

import Foundation

struct ElapsedTime {
    
    static func format(from: Date, forceDate: Bool = false) -> String {
        
        let elapsedTime = from.timeIntervalSinceNow * -1
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        
        if elapsedTime < 3600{
            formatter.dateFormat = "\(Int(elapsedTime/60))分前"
        } else if elapsedTime < 86400 {
            formatter.dateFormat = "H:mm"
        } else if elapsedTime < 172800 {
            formatter.dateFormat = "昨日"
        } else if elapsedTime < 691200{
            formatter.dateFormat = "EEEE"
        } else {
            formatter.dateFormat = "M月d日"
        }
        
        if forceDate { formatter.dateFormat = "M月d日" }
        
        return formatter.string(from: from)
    }
    
    static func elapsedTime(from: Date) -> String {
        
        let now = Date()
        let span = now.timeIntervalSince(from)
        
        let secondSpan = Int(floor(span))
        let minuteSpan = Int(floor(span/60))
        let hourSpan   = Int(floor(span/60/60))
        let daySpan    = Int(floor(span/60/60/24))

        if secondSpan < 60 {
            // 秒数的な差がある場合
            return "\(secondSpan)秒前"
            
        } else if minuteSpan > 0 && minuteSpan < 60 {
            // 分数的な差がある場合
            return "\(minuteSpan)分前"
            
        } else if hourSpan > 0 && hourSpan < 24 {
            // 時刻的な差がある場合
            return "\(hourSpan)時間前"
            
        } else if daySpan > 0 && daySpan < 8 {
            // 日数的な差がある場合
            return "\(daySpan)日前"
            
        } else {

            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
            formatter.dateFormat = "yyyy/MM/dd"
            
            let format = formatter.string(from: from)
            return format
        }
    }
    
    static func notificationFormat(from: Date) -> String {
        
        let now = Date()
        let span = now.timeIntervalSince(from)
        
        let secondSpan = Int(floor(span))
        let minuteSpan = Int(floor(span/60))
        let hourSpan   = Int(floor(span/60/60))
        let daySpan    = Int(floor(span/60/60/24))
        let weekSpan   = Int(floor(span/7/60/60/24))

        if secondSpan < 60 {
            // 秒数的な差がある場合
            return "\(secondSpan)秒前"
            
        } else if minuteSpan > 0 && minuteSpan < 60 {
            // 分数的な差がある場合
            return "\(minuteSpan)分前"
            
        } else if hourSpan > 0 && hourSpan < 24 {
            // 時刻的な差がある場合
            return "\(hourSpan)時間前"
            
        } else if daySpan > 0 && daySpan < 8 {
            // 日数的な差がある場合
            return "\(daySpan)日前"
            
        } else {
            return "\(weekSpan)週間前"
        }
    }
    
    static func customFormat(from: Date, type: String) -> String {
        
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        
        switch type {
        case "fullTime": formatter.dateFormat = "M月d日 H:mm"; break
        case "time": formatter.dateFormat = "H:mm"; break
        default: break
        }
        
        return formatter.string(from: from)
    }
}
