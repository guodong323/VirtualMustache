//
//  ContentView.swift
//  Horizontal3DScroll
//
//  Created by Christopher Gonzalez on 2024-07-27.
//

import SwiftUI

struct ContentView: View {
    let data: [UIImage]
    
    @State private var selectedItem: UIImage? = nil
    
    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    Spacer().frame(width: 135/2)
                    ForEach(data.indices, id: \.self) { index in
                        GeometryReader { geometry in
                            ZStack {
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing))
                                    .frame(width: 135, height: 135)

                                Image(uiImage: data[index])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            }
                            .rotation3DEffect(
                                Angle(
                                    degrees: geometry.frame(
                                    in: .global).minX - 16) / -20,
                                axis: (x: 0.0, y: 1.0, z: 0.0),
                                anchor: .center,
                                anchorZ: 0,
                                perspective: 1
                            )
                            .onChange(of: geometry.frame(in: .global).midX) { midX in
                                let screenWidth = UIScreen.main.bounds.width
                                if abs(midX - screenWidth / 2) < 20 {
                                    selectedItem = data[index]
                                    print("Current Image: Mustache_\(index + 1)")
                                    NotificationCenter.default.post(
                                        name: Notification.Name("MustacheSelected"),
                                        object: nil,
                                        userInfo: ["selectedIndex": index]
                                    )
                                }
                            }
                        }
                        .frame(width: 150, height: 150)
                    }
                    Spacer().frame(width: 135 / 2)
                }
                .padding()
            }
        }
        .background(Color.clear)
        .onAppear {
            if let firstImage = data.first {
                selectedItem = firstImage
                print("Selected Image: Mustache_1")
                
                NotificationCenter.default.post(
                    name: Notification.Name("MustacheSelected"),
                    object: nil,
                    userInfo: ["selectedIndex": 0]
                )
            }
        }
    }
}
