import UIKit
import Flutter
import GoogleMaps
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {
override func application(
_ application: UIApplication,
didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
GeneratedPluginRegistrant.register(with: self)
GMSServices.provideAPIKey("AIzaSyD9lyWXaDm86LMhTaPtlHSXK4mYH5Wt0bg")

// Google Sign-In 초기화
if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
   let plist = NSDictionary(contentsOfFile: path),
   let clientId = plist["CLIENT_ID"] as? String {
    let gidConfiguration = GIDConfiguration(clientID: clientId)
    GIDSignIn.sharedInstance.configuration = gidConfiguration
}

return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}

override func application(_ app: UIApplication, 
                         open url: URL,
                         options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
}
}