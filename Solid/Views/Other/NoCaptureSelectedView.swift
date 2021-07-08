//
//  NoCaptureSelectedView.swift
//  Solid
//
//  Created by Andrew Sawyer on 7/6/21.
//

import SwiftUI
import AppKit

struct NoCaptureSelectedView: View {
    @State private var showingTips = false
    
    var body: some View {
        VStack {
            HStack {
                Image("SolidIcon")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: 140)
             
                VStack(alignment: .leading, spacing: 2) {
                    Text("Solid")
                        .font(.title)
                        .bold()
                        //.padding(.bottom, 0.5)
                    
                    Text("Click the + to select a folder of\nimages to turn into a 3D model")
                        .padding(.bottom, 8)
                    
                    Button {
                        showingTips = true
                    } label: {
                        Text("Capture Tips")
                    }
                    .popover(isPresented: $showingTips) {
                        VStack(alignment: .leading, spacing: 4) {
                            //Text("Here are some tips to remember:")
                            //    .bold()
                            Text("• Capture from all angles")
                            Text("• Flip the object to capture all sides")
                            Text("• Keep uniform lighting")
                            Text("• 20-200 images will yield a good results")
                        }
                        .font(.body)
                        .padding()
                    }
                }
            }
        }
        .padding()
    }
}
