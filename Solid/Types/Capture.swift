//
//  Model.swift
//  Solid
//
//  Created by Andrew Sawyer on 6/19/21.
//

import Foundation
import RealmSwift
import SwiftUI

@objc enum CaptureState: Int {
    case configuring
    case processing
    case stored
}

extension CaptureState: CustomStringConvertible {
    var description: String {
        switch self {
        case .configuring:
            return "Configuring"
        case .processing:
            return "Processing"
        case .stored:
            return "Stored"
        }
    }
}

@objcMembers class Capture: Object, ObjectKeyIdentifiable {
    
    //Stored by Realm
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var stateValue: Int = 0
    @Persisted var name: String
    @Persisted var dateCreated: Date
    @Persisted var importFolderRelativePath: String
    @Persisted var processedFiles = RealmSwift.List<ProcessedFile>()
    
    //Not stored by Realm
    var state: CaptureState {
        get {
            return CaptureState(rawValue: stateValue) ?? .configuring
        }
        set {
            stateValue = newValue.rawValue
        }
    }
    lazy var formatedDate: String = {
        //display time created
        if Calendar.current.isDateInToday(dateCreated) {
            return dateCreated.formatted(date: .omitted, time: .shortened)
        } else {
            return dateCreated.formatted(date: .abbreviated, time: .omitted)
        }
        
        //unable to get .named to work
        //let dateFormater = RelativeDateTimeFormatter()
        //dateFormater.dateTimeStyle = .numeric
        //dateFormater.unitsStyle = .abbreviated
        //return dateFormater.localizedString(for: dateCreated, relativeTo: currentDate)
    }()
    
    
    init(name: String, rawUrl: URL?) {
        self.name = name
        
        let date = Date()
        dateCreated = date
        
        //dateCreated = Date(timeIntervalSince1970: 100) //long term debug date
        //dateCreated = Calendar.current.date(byAdding: .day, value: -5, to: Date())! //relative debug date
        
        self.importFolderRelativePath = rawUrl?.relativePath ?? ""
        
        super.init()
    }
    
    required convenience override init() {
        self.init(name: "New Model", rawUrl: nil)
    }

    static func == (lhs: Capture, rhs: Capture) -> Bool {
        return lhs._id == rhs._id
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
}
