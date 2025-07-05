//
//  UpdateMessageView.swift
//  CocoonExample
//
//  Created by 佐藤汰一 on 2025/07/05.
//

import SwiftUI

struct UpdateMessageView: View {
    @Environment(\.messageClient) var messageClient
    @Environment(\.dismiss) var dismiss
    
    @State private var updateText: String
    private let id: String
    
    init(message: Message) {
        self.updateText = message.text
        self.id = message.id
    }
    
    var body: some View {
        VStack {
            TextField("メッセージの修正", text: $updateText)
                .textFieldStyle(.roundedBorder)
                .padding()
            Spacer()
                .frame(height: 30)
            Button {
                Task {
                    await tappedUpdateButton()
                }
            } label: {
                Text("Update")
            }
            .buttonStyle(.bordered)
            Spacer()
        }
    }
}

private extension UpdateMessageView {
    func tappedUpdateButton() async {
        await messageClient.update(
            .init(id: id, text: updateText)
        )
        dismiss()
    }
}

#Preview {
    UpdateMessageView(message: .init(id: "id", text: "Sample"))
        .environment(
            \.messageClient,
             EnvironmentValues.previewMessageClient
        )
}
