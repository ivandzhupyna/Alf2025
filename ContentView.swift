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
    }
}

#Preview {
    ContentView()
} 