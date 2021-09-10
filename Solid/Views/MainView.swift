//
//  ContentView.swift
//  Solid
//
//  Created by Andrew Sawyer on 6/18/21.
//

import SwiftUI
import RealmSwift
import UniformTypeIdentifiers

struct MainView: View {
    
    @ObservedObject var model: MainViewModel
    
    @State private var selectedCaptureID: ObjectId?
    var selectedCapture: Capture? {
        return captures.first { capture in
            capture._id == selectedCaptureID
        }
    }
    
    @State private var importFileBrowserDisplayed: Bool = false
    @State private var fileExportIsDisplayed: Bool = false
    
    @State private var showingTips = false

    @ObservedResults(Capture.self, sortDescriptor: SortDescriptor(keyPath: "dateCreated", ascending: false)) var captures
    
    var body: some View {
        //List & Preview View
        CaptureNavigationView(selectedCaptureID: $selectedCaptureID, model: model)
            
        //Toolbar
        .toolbar {
            
            ToolbarItem(placement: ToolbarItemPlacement.navigation) {
                Button(action: {
                    //from https://developer.apple.com/forums/thread/651807?answerId=617555022#617555022
                    NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
                }, label: {
                    Image(systemName: "sidebar.left")
                })
            }
            
            ToolbarItem(placement: ToolbarItemPlacement.automatic) {
                Button {
                    showingTips = true
                } label: {
                    Image(systemName: "info.circle")
//                    Text("Capture Tips")
                }
                .popover(isPresented: $showingTips) {
                    TipsView(showsHeadline: true)
                }
            
            }
            
            
            ToolbarItem(placement: ToolbarItemPlacement.destructiveAction) {
                Button(action: {
                    guard let selectedCapture = selectedCapture else { return }
                    model.storage.delete(captures: [selectedCapture], model: model)
                    
                    self.selectedCaptureID = captures.first?._id
                    
                    debugPrint("deleted \(selectedCapture.name)")
                }, label: {
                    Image(systemName: "trash")
                })
                .disabled(selectedCapture == nil)
            }

            ToolbarItem(placement: .automatic) {
                Button(action: {
                    guard let selectedCapture = selectedCapture else { return }
                    debugPrint("sharing all quality levels of \(selectedCapture.name)")
                    fileExportIsDisplayed = true
                }, label: {
                    Image(systemName: "square.and.arrow.up")
                })
                    .disabled(selectedCapture == nil || selectedCapture?.state != .stored)
            }

            ToolbarItem(placement: ToolbarItemPlacement.primaryAction) {
                Button(action: {
                    importFileBrowserDisplayed = true
                }, label: {
                    Image(systemName: "plus")
                })
            }

        }
        
        //File Import
        .fileImporter(
            isPresented: $importFileBrowserDisplayed,
            allowedContentTypes: [UTType.folder],
            allowsMultipleSelection: false,
            onCompletion: { result in
                do  {
                    let url = try result.get()
                    debugPrint(url)
                    if let firstUrl = url.first {
                        let capture = Capture(name: "New Model", rawUrl: firstUrl)
                        $captures.append(capture)
                        model.importConfigurations.append(
                            ImportConfiguration(for: capture)
                        )
                        selectedCaptureID = capture._id
                    }
                    debugPrint("file importer completion")
                } catch {
                    debugPrint("error with importing")
                }
            }
        )
        
        .fileExporter(
            isPresented: $fileExportIsDisplayed,
            documents: Storage.exportItems(for: selectedCapture),
            contentType: UTType.folder,
            onCompletion: { result in
                debugPrint(result)
            })
        
        //Navigation Title / Subtitle
        .navigationTitle(selectedCapture?.name ?? "")
        .navigationSubtitle(selectedCapture?.dateCreated.formatted(date: .abbreviated, time: .shortened) ?? "")
        
        
        //present first capture on appear
        .onAppear {
            selectedCaptureID = captures.first?._id
        }
    }
}
