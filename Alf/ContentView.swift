//
//  ContentView.swift
//  Alf
//
//  Created by Ivan Dzhupyna on 05.05.25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            LessonsView()
                .tabItem {
                    Label("Lessons", systemImage: "book.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
