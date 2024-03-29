//
//  ModelListCell.swift
//  Solid
//
//  Created by Andrew Sawyer on 6/19/21.
//

import SwiftUI
import RealmSwift

struct ModelListCell: View {
    
    @ObservedRealmObject var capture: Capture
    
    var body: some View {
        HStack() {
            VStack(alignment: .leading) {
                TextField("", text: $capture.name)
                    .textFieldStyle(.plain)
                
                Text(capture.formatedDate)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if capture.state != .stored {
                Text(capture.state.description)
                .padding([.horizontal], 5)
                .padding([.vertical], 2)
                .foregroundStyle(.primary)
                .background(.gray)
                .cornerRadius(5)
            }
        }
    }
}
