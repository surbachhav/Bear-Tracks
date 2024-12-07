//
//  Bear_TracksApp.swift
//  Bear-Tracks
//
//  Created by Surabhi Bachhav on 12/6/24.
//

import SwiftUI
import GoogleSignIn
import GoogleAPIClientForRESTCore
import GTMSessionFetcherCore

@main
struct Bear_TracksApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    let googleSignInConfig = GIDConfiguration(clientID: "544106969302-d1noh8cv8elf64mhadmc55l5jbut5qsb.apps.googleusercontent.com")

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}
