//
//  Storage.swift
//  Solid
//
//  Created by Andrew Sawyer on 6/19/21.
//

import Foundation
import SwiftUI
import RealmSwift
import RealityFoundation

class Storage {
    var realm: Realm
    
    init(with realm: Realm) {
        self.realm = realm
    }
    
    func newCapture(with folderUrl: URL) {
        let capture = Capture(name: "New Model", rawUrl: folderUrl)
        do {
            try realm.write {
                realm.add(capture)
            }
        } catch {
            debugPrint("could not add new capture")
        }
    }
    
    func new(_ processedFile: ProcessedFile, for capture: Capture) {
        do {
            try realm.write {
                if let thawedCapture = capture.thaw() {
                    thawedCapture.processedFiles.append(processedFile)
                }
            }
        } catch {
            debugPrint("couldn't add new processed file")
        }
    }
    
    func delete(captures: [Capture], model: MainViewModel? = nil) {
        debugPrint("deleting \(captures.count) captures")
       
        var thawedCaptures: [Capture] = []
        
        for capture in captures {
            if let model = model {
                stopProcessing(for: capture, with: model)
            }
            Storage.deleteFiles(for: capture)
            
            if let thawed = capture.thaw() {
                thawedCaptures.append(thawed)
            }
        }
        
        do {
            try realm.write {
                realm.delete(thawedCaptures)
            }
        } catch {
            debugPrint("couldn't add new processed file")
        }
    }
    
    private static func deleteFiles(for capture: Capture) {
        for processedFile in capture.processedFiles {
            let url = Storage.url(for: capture, with: processedFile.quality)
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    private func stopProcessing(for capture: Capture, with model: MainViewModel) {
        for captureGenerator in model.captureGenerators {
            if
                captureGenerator.capture == capture,
                let index = model.captureGenerators.firstIndex(of: captureGenerator) {
                
                captureGenerator.session?.cancel()
                model.captureGenerators.remove(at: index)
                
                break
            }
        }
    }
    
    static private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    static func url(for capture: Capture, with quality: PhotogrammetrySession.Request.Detail, includeUsdzExtension: Bool = true) -> URL {
        let id = "\(capture._id)_\(quality.name)"
        if includeUsdzExtension {
            return getDocumentsDirectory().appendingPathComponent("\(id).usdz")
        } else {
            return getDocumentsDirectory().appendingPathComponent(id, isDirectory: true)
        }
    }
    
    static func fileExists(at url: URL) -> Bool {
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    static func exportItems(for capture: Capture?) -> [ExportItem] {
        guard let capture = capture else { return [] }
        
        var exportItems: [ExportItem] = []
        
        for quality in PhotogrammetrySession.Request.Detail.allCases {
            let id = "\(capture._id)_\(quality.name)"
            debugPrint("ID \(capture._id)")
            //USDZ
            let fileUrl = getDocumentsDirectory().appendingPathComponent("\(id).usdz")
            if FileManager.default.fileExists(atPath: fileUrl.path) {
                let item = ExportItem(url: fileUrl)
                exportItems.append( item )
            }
            
            //USDA & OBJ folder
            let folderUrl = getDocumentsDirectory().appendingPathComponent(id, isDirectory: true)
            if FileManager.default.fileExists(atPath: folderUrl.path) {
                let item = ExportItem(url: folderUrl)
                exportItems.append( item )
            }
        }
        return exportItems
    }
}

import UniformTypeIdentifiers
enum ExportItemErrors: Error {
    case initFromReadConfigurationError
}
struct ExportItem: FileDocument {
    static var readableContentTypes: [UTType] = [.folder]
    
    var url: URL
    
    init(url: URL) {
        self.url = url
    }
    
    init(configuration: ReadConfiguration) throws {
        if let configUrl = configuration.file.symbolicLinkDestinationURL {
            url = configUrl
        } else {
            throw ExportItemErrors.initFromReadConfigurationError
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return try FileWrapper(url: url, options: .immediate)
    }
    
    
}
