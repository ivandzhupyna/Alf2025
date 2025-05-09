import SwiftUI

struct LessonsView: View {
    var body: some View {
        NavigationStack {
            List {
                Text("Lesson 1")
                Text("Lesson 2")
                Text("Lesson 3")
            }
            .navigationTitle("Lessons")
        }
    }
}

#Preview {
    LessonsView()
} 