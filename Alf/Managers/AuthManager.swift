import Foundation
import FirebaseAuth
import GoogleSignIn
import Firebase
import FirebaseFirestore

class AuthManager: ObservableObject {
    @Published var user: User?
    @Published var isSignedIn: Bool = false
    @Published var userProfile: UserProfile?
    @Published var errorMessage: String?
    
    struct UserProfile {
        let name: String
        let surname: String
        let avatarURL: URL?
    }
    
    init() {
        print("Initializing AuthManager...")
        self.user = Auth.auth().currentUser
        self.isSignedIn = self.user != nil
        self.loadUserProfile()
        
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            print("Auth state changed. User: \(user?.uid ?? "nil")")
            self?.user = user
            self?.isSignedIn = user != nil
            self?.loadUserProfile()
        }
    }
    
    func signInWithGoogle() {
        print("Starting Google Sign-In process...")
        errorMessage = nil
        
        // Check if Firebase is initialized
        guard let firebaseApp = FirebaseApp.app() else {
            errorMessage = "Firebase is not initialized"
            print("Error: \(errorMessage!)")
            return
        }
        
        // Get client ID
        guard let clientID = firebaseApp.options.clientID else {
            errorMessage = "Could not get Firebase client ID"
            print("Error: \(errorMessage!)")
            print("Firebase options: \(firebaseApp.options)")
            print("Available options:")
            print("- API Key: \(firebaseApp.options.apiKey)")
            print("- Project ID: \(firebaseApp.options.projectID ?? "nil")")
            print("- Bundle ID: \(firebaseApp.options.bundleID ?? "nil")")
            print("- Google App ID: \(firebaseApp.options.googleAppID ?? "nil")")
            return
        }
        print("Firebase client ID obtained: \(clientID)")
        
        // Get root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            errorMessage = "Could not get root view controller"
            print("Error: \(errorMessage!)")
            return
        }
        print("Root view controller obtained")
        
        // Start Google Sign-In
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = "Google Sign-In error: \(error.localizedDescription)"
                print("Error: \(self?.errorMessage ?? "")")
                return
            }
            
            print("Google Sign-In successful")
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self?.errorMessage = "Could not get user or idToken"
                print("Error: \(self?.errorMessage ?? "")")
                return
            }
            print("Google user and idToken obtained")
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            print("Firebase credential created")
            
            // Sign in with Firebase
            Auth.auth().signIn(with: credential) { [weak self] result, error in
                if let error = error {
                    self?.errorMessage = "Firebase Sign-In error: \(error.localizedDescription)"
                    print("Error: \(self?.errorMessage ?? "")")
                    return
                }
                
                print("Firebase Sign-In successful")
                // Save user profile to Firestore
                self?.saveUserProfile()
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            self.user = nil
            self.isSignedIn = false
            self.userProfile = nil
            print("Successfully signed out")
        } catch {
            errorMessage = "Sign out error: \(error.localizedDescription)"
            print("Error: \(errorMessage ?? "")")
        }
    }
    
    private func loadUserProfile() {
        guard let user = user else { return }
        print("Loading profile for user: \(user.uid)")
        
        // Load from Firestore
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).getDocument { [weak self] (snapshot: DocumentSnapshot?, error: Error?) in
            if let error = error {
                self?.errorMessage = "Error loading user profile: \(error.localizedDescription)"
                print("Error: \(self?.errorMessage ?? "")")
                return
            }
            
            if let data = snapshot?.data() {
                print("User profile data found: \(data)")
                self?.userProfile = UserProfile(
                    name: data["name"] as? String ?? "",
                    surname: data["surname"] as? String ?? "",
                    avatarURL: URL(string: data["avatarURL"] as? String ?? "")
                )
            } else {
                print("No user profile found, creating new one")
                // Create new profile if doesn't exist
                self?.saveUserProfile()
            }
        }
    }
    
    private func saveUserProfile() {
        guard let user = user else { return }
        print("Saving profile for user: \(user.uid)")
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.uid)
        
        // Get user info from Google
        let name = user.displayName?.components(separatedBy: " ").first ?? ""
        let surname = user.displayName?.components(separatedBy: " ").last ?? ""
        let avatarURL = user.photoURL?.absoluteString ?? ""
        
        let userData: [String: Any] = [
            "name": name,
            "surname": surname,
            "avatarURL": avatarURL,
            "lastUpdated": Date()
        ]
        
        print("Saving user data: \(userData)")
        
        userRef.setData(userData) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Error saving user profile: \(error.localizedDescription)"
                print("Error: \(self?.errorMessage ?? "")")
            } else {
                print("User profile saved successfully")
                self?.userProfile = UserProfile(
                    name: name,
                    surname: surname,
                    avatarURL: URL(string: avatarURL)
                )
            }
        }
    }
} 