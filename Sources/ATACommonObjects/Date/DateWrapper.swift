//
//  File.swift
//  
//
//  Created by GG on 19/03/2021.
//

import Foundation

public enum DateWrapper {
    case now, date(_: Date)
    
    var date: Date {
        switch self {
        case .now: return Date()
        case .date(let date): return date
        }
    }
}
