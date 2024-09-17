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
}
