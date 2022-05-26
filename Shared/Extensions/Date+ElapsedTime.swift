//
//  Date+ElapsedTime.swift
//  ManaGuide (iOS)
//
//  Created by Vito Royeca on 5/13/22.
//

import Foundation

extension Date {
    
    func elapsedTime() -> String {
        
        let interval = Calendar.current.dateComponents([.day, .hour, .minute], from: self, to: Date())
        
        if let day = interval.day, day > 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: self)
        } else if let hour = interval.hour, hour > 0 {
            return hour == 1 ? "\(hour)" + " " + "hr ago" :
                "\(hour)" + " " + "hrs ago"
        } else if let minute = interval.minute, minute > 0 {
            return minute == 1 ? "\(minute)" + " " + "min ago" :
                "\(minute)" + " " + "mins ago"
        } else {
            return "a moment ago"
        }
        
    }
}
