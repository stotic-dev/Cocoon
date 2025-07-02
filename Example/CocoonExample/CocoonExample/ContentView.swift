//
//  ContentView.swift
//  CocoonExample
//
//  Created by 佐藤汰一 on 2025/07/01.
//

import SwiftUI

struct ContentView: View {
    @State var inputText: String = ""
    @State var messageList: [Message] = []
    
//    @Environment(\.messageClient) var messageClient
    
    var body: some View {
        VStack {
            TextField("Input Text", text: $inputText)
                .textFieldStyle(.roundedBorder)
            Spacer()
                .frame(height: 30)
            Button {
                
            } label: {
                Text("Save")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .task {
//            messageList = await messageClient.fetch()
//                .map { .init(id: $0.id.uuidString, text: $0.message) }
        }
    }
}

#Preview {
    ContentView()
}
