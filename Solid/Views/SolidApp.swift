//
//  SolidApp.swift
//  Solid
//
//  Created by Andrew Sawyer on 6/18/21.
//

import SwiftUI
import RealmSwift

@main
struct SolidApp: SwiftUI.App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject var model: MainViewModel = {
        let realm = try! Realm()
        let storage = Storage(with: realm)
        return MainViewModel(storage: storage)
    }()
    
    
    var body: some Scene {
        WindowGroup {
            MainView(model: model)
        }
        
        .commands {
            CommandGroup(replacing: .newItem) {
                EmptyView()
            }
            CommandGroup(replacing: .help) {
                EmptyView()
            }
            
            
            CommandGroup(replacing: .appInfo) {
//                if let contributeUrl = URL(string: "https://github.com/aswyer/Solid") {
//                    Link("Solid Open-Source Project", destination: contributeUrl)
//                }
//                
                Divider()
                
                if
                    let gsgUrl = URL(string: "https://greyscalegorilla.com"),
                    let hdriHavenUrl = URL(string: "https://hdrihaven.com")
                {
                    Text("Environments from:")
                    Link("Greyscalegorilla", destination: gsgUrl)
                    Link("HDRIHaven", destination: hdriHavenUrl)
                }
            }
            SidebarCommands()
        }
        .windowToolbarStyle( UnifiedWindowToolbarStyle() )
        
    }
}


class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    
    @ObservedResults(Capture.self, sortDescriptor: SortDescriptor(keyPath: "dateCreated", ascending: false)) var captures
    
    var window: NSWindow? {
        NSApplication.shared.windows.first
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        window?.delegate = self
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        let realm = try! Realm()
        let storage = Storage(with: realm)
        
        var capturesToDelete: [Capture] = []
        
        for capture in captures {
            if capture.state != .stored {
                capturesToDelete.append(capture)
            }
        }
        
        storage.delete(captures: capturesToDelete)
    }
    
    var shouldQuit: Bool?
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if shouldQuit == nil {
            shouldQuit = appShouldQuit()
        }
        
        if shouldQuit ?? true {
            return .terminateNow
        } else {
            shouldQuit = nil
            return .terminateCancel
        }
        

    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        shouldQuit = appShouldQuit()
        
        if shouldQuit ?? true {
            return true
        } else {
            shouldQuit = nil
            return false
        }
    }
    
    func appShouldQuit() -> Bool {
        for capture in captures {
            if capture.state == .processing {
                let alert = NSAlert()
                alert.alertStyle = .critical
                
                alert.messageText = "Do you want to continue processing?"
                alert.informativeText = "Solid is currently processing a capture. If you quit the capture will be deleted"
                
                alert.addButton(withTitle: "Continue")
                alert.addButton(withTitle: "Quit")
                
                let response = alert.runModal()
                
                if response == .alertFirstButtonReturn {
                    return false
                }
                break
            }
        }
        
        return true
    }

}
