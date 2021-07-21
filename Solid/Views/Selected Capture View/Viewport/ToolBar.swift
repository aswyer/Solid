//
//  QualitySelector.swift
//  Solid
//
//  Created by Andrew Sawyer on 6/30/21.
//

import SwiftUI
import RealmSwift
import RealityKit

struct ToolBar: View {
    
    @ObservedObject var model: MainViewModel
    @ObservedRealmObject var capture: Capture
    
    @State var showLightingPopover = false
    
    @AppStorage("lightingEnvironment") var lightingEnvironment = Defaults.lightingEnvironment
    @AppStorage("isBackgroundVisible") var isBackgroundVisible = Defaults.isBackgroundVisible
    @AppStorage("wantsDOF") var wantsDOF = Defaults.wantsDOF
    @AppStorage("focusDistance") var focusDistance = Defaults.focusDistance
    @AppStorage("environmentRotation") var environmentRotation = Defaults.environmentRotation
    
    @Binding var selectedPreviewQuality: PhotogrammetrySession.Request.Detail
    
    var body: some View {
        HStack {
            
            //Reset Frame
            Button {
                model.viewportModel.resetFrame()
            } label: {
                Image(systemName: "camera.metering.spot") //camera.viewfinder
                    .font(.body.weight(.bold))
            }
        
            //Lighting Controls
            Button {
                showLightingPopover = true
            } label: {
                Image(systemName: "rotate.3d")
                    .font(.body.weight(.bold))
            }
            .popover(isPresented: $showLightingPopover, arrowEdge: .top) {
                VStack(alignment: .leading) {
                    Text("Environment")
                        .font(.headline)
                    
                    //making custom grid becuase weird animation glitch with LazyVGrid
                    VStack {
                        ForEach(0..<2) { row in
                            HStack {
                                ForEach(0..<2) { column in
                                    
                                    let item = LightingEnvironment.allCases[row * 2 + column]
                                    let selected = lightingEnvironment.rawValue == item.rawValue
                                    
                                    Button {
                                        lightingEnvironment = item
                                    } label: {
                                        ZStack {
                                            Image("environmentPreview_\(item.rawValue)")
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .cornerRadius(8)
                                                .opacity(selected ? 0.5 : 1)
                                            Image(systemName: "checkmark")
                                                .font(.body.weight(.bold))
                                                .opacity(selected ? 1 : 0)
                                            
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    
                                }
                            }
                        }
                    }
                    .frame(width: 90*2, height: 60*2)
                    .animation(.default, value: lightingEnvironment)
                    
                    
                    Slider(value: $environmentRotation, in: 0...1, label: {
                        Text("Rotate:")
                    })
                    
                    Toggle("Show Environment", isOn: $isBackgroundVisible)
                        .padding(.bottom, 2)
                        
                    
                    Divider()
                    
                    Toggle("Depth of Field", isOn: $wantsDOF)
                        .padding(.top, 2)
                    
                    if wantsDOF {
                        Slider(value: $focusDistance, in: Defaults.minFocusDistance...Defaults.maxFocusDistance, label: {
                            Text("Focus Distance:")
                        })
                    }
                }
                .padding()
            }
            
            //Quality Picker
            //if capture.processedFiles.count > 1 {
                Picker(selection: $selectedPreviewQuality, label: EmptyView()) {
                    ForEach(capture.processedFiles) { file in
                        Text(file.quality.name).tag(file.quality)
                    }
                }
                .pickerStyle(.segmented)
                .scaledToFit()
            //}
        }
    }
}

//struct QualitySelector_Previews: PreviewProvider {
//    static var previews: some View {
//        QualitySelector(capture: Capture())
//    }
//}
