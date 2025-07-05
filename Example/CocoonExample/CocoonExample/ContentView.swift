//
//  ContentView.swift
//  CocoonExample
//
//  Created by 佐藤汰一 on 2025/07/01.
//

import Combine
import SwiftUI

struct ContentView: View {
    @State var inputText: String = ""
    @State var messageList: [Message] = []
    @State var updateMessage: Message?
    
    @Environment(\.messageClient) var messageClient
    
    var body: some View {
        VStack {
            TextField("Input Text", text: $inputText)
                .textFieldStyle(.roundedBorder)
            Spacer()
                .frame(height: 30)
            Button {
                Task {
                    await tappedSaveButton()
                }
            } label: {
                Text("Save")
            }
            .buttonStyle(.bordered)
            .disabled(inputText.isEmpty)
            List {
                ForEach(messageList) { message in
                    Button(message.text) {
                        updateMessage = message
                    }
                }
                .onDelete { targets in
                    Task {
                        await swipeDelete(targets)
                    }
                }
            }
            .listStyle(.plain)
            Spacer()
        }
        .padding()
        .task {
            await onAppear()
        }
        .sheet(item: $updateMessage) {
            UpdateMessageView(message: $0)
                .presentationDetents([
                    .medium,
                    .height(300)
                ])
        }
    }
}

private extension ContentView {
    func onAppear() async {
        messageList = await messageClient.fetch()
        let publisher = await messageClient.observe()
        for await currentMessageList in publisher.values {
            messageList = currentMessageList
        }
    }
    
    func tappedSaveButton() async {
        await messageClient.save(
            .init(id: UUID().uuidString, text: inputText)
        )
        inputText = ""
    }
    
    func swipeDelete(_ targets: IndexSet) async {
        for index in targets {
            let target = messageList[index]
            await messageClient.delete(target)
        }
        messageList.remove(atOffsets: targets)
    }
}

#Preview {
    ContentView()
        .environment(
            \.messageClient,
             EnvironmentValues.previewMessageClient
        )
}
