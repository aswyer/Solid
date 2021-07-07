//
//  ImportOptionsView.swift
//  Solid
//
//  Created by Andrew Sawyer on 6/19/21.
//

import SwiftUI
import RealmSwift
import RealityKit

struct ImportOptionsView: View {
    
    @ObservedObject var model: ContentViewModel
    @ObservedRealmObject var capture: Capture
    
    @ObservedObject var importConfiguration: ImportConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            
            //Name
            TextField("Capture Name: ", text: $capture.name)
                .font(.headline)
                .textFieldStyle(.roundedBorder)
            
            
            let gridItem = GridItem(alignment: .topLeading)
            LazyVGrid(columns: [gridItem, gridItem], spacing: 20) {
                //Folder Url
                if let _ = importConfiguration.rawFolderUrl {
                    Text("Folder Location:")
                        .bold()
                    VStack(alignment: .leading) {
                        Text(importConfiguration.relativePath)
                        
                        //Number of Images
                        if let numberOfImages = importConfiguration.numberOfImages() {
                            Text("\(numberOfImages) Images")
                                .bold()
                                .padding(.top, 2)
                        }
                    }
                }
                
                //Quality Selection
                VStack(alignment: .leading) {
                    Text("Quality:")
                        .bold()
                    Text("Preview, medium, and reduced are iOS ready. Use full & raw for pro workflows.")
                }
                VStack(alignment: .leading) {
                    ForEach(importConfiguration.qualitySelections.indices) { index in
                        Toggle(
                            importConfiguration.qualitySelections[index].quality.name,
                            isOn: $importConfiguration.qualitySelections[index].selected
                        )
                    }
                }
            }
            
            //Generate Button
            Button {
                model.captureGenerators.append(
                    CaptureGenerator(for: capture, with: importConfiguration, model: model)
                )
            } label: {
                Text("Generate Model")
                    .frame(maxWidth: .infinity)
            }
            .disabled(importConfiguration.numberOfQualitiesSelected <= 0)
            //.keyboardShortcut(.defaultAction)
            
        }
    }
}

extension PhotogrammetrySession.Request.Detail: CaseIterable {
    public static var allCases: [PhotogrammetrySession.Request.Detail] = [
        .preview, .reduced, .medium, .full, .raw
    ]
}

//struct ImportOptionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        let capture = Capture(
//            name: "Testing",
//            rawUrl: URL(string: "url/")
//        )
//        ImportOptionsView(
//            model: ContentViewModel(storage: Storage(with: try! Realm())),
//            capture: capture,
//            importConfiguration: ImportConfiguration(for: capture)
//        )
//    }
//}
