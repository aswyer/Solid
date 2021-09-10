//
//  CaptureNavigationView.swift
//  Solid
//
//  Created by Andrew Sawyer on 7/6/21.
//

import SwiftUI
import RealmSwift

struct CaptureNavigationView: View {
    
    @Binding var selectedCaptureID: ObjectId?
    var selectedCapture: Capture? {
        return captures.first { capture in
            capture._id == selectedCaptureID
        }
    }
    
    @ObservedObject var model: MainViewModel
    @ObservedResults(Capture.self, sortDescriptor: SortDescriptor(keyPath: "dateCreated", ascending: false)) var captures
    
    var body: some View {
        //Normal Sidebar and SelectedCaptureView
        if captures.count > 0 {
            NavigationView {
                SwiftUI.List(selection: $selectedCaptureID) {
                    ForEach(captures) { capture in
                        ModelListCell(capture: capture)
                            .frame(idealWidth: 40)
                            .tag(capture._id)
                    }
                }
                .listStyle(.sidebar)
                .frame(minWidth: 100, idealWidth: 250)
                
                if let selectedCapture = selectedCapture {
                    SelectedCaptureView(model: model, capture: selectedCapture)
                } else {
                    NoCaptureSelectedView()
                }
            }
            
        //No Captures View
        } else {
            NavigationView {
                EmptyView()
                NoCaptureSelectedView()
            }
        }
    }
}

