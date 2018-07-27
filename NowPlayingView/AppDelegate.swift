import UIKit

@UIApplicationMain
class AppDelegate: UIResponder,
    UIApplicationDelegate, SPTAppRemoteDelegate {

    fileprivate let redirectUri = "lyftjukebox://callback"
    fileprivate let clientIdentifier = "e7b8a812fcc94fb089b19e22761bddb2"
    fileprivate let name = "Lyft Jukebox"

    // keys
    static fileprivate let kAccessTokenKey = "access-token-key"

    // output parameter!
    var accessToken = UserDefaults.standard.string(forKey: kAccessTokenKey) {
        didSet {
            let defaults = UserDefaults.standard
            defaults.set(accessToken, forKey: AppDelegate.kAccessTokenKey)
            defaults.synchronize()
        }
    }

    
    var playerViewController: ViewController {
        get {
            let navController = self.window?.rootViewController?.childViewControllers[0] as! UINavigationController
            return navController.topViewController as! ViewController
        }
    }
    
    var window: UIWindow?

    lazy var appRemote: SPTAppRemote = {
        let connectionParams = SPTAppRemoteConnectionParams(clientIdentifier: self.clientIdentifier,
                                                            redirectURI: self.redirectUri,
                                                            name: self.name,
                                                            accessToken: self.accessToken,
                                                            defaultImageSize: CGSize(width: 0, height: 0),
                                                            imageFormat: .any);
        let appRemote = SPTAppRemote(connectionParameters: connectionParams, logLevel: .debug)
        appRemote.delegate = self
        return appRemote
    }()

    class var sharedInstance: AppDelegate {
        get {
            return UIApplication.shared.delegate as! AppDelegate
        }
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        let parameters = appRemote.authorizationParameters(from: url);

        if let access_token = parameters?[SPTAppRemoteAccessTokenKey] {
            appRemote.connectionParameters.accessToken = access_token
            self.accessToken = access_token
        } else if let error_description = parameters?[SPTAppRemoteErrorDescriptionKey] {
            playerViewController.showError(error_description);
        }

        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        print("I'm out of focus!")
        playerViewController.appRemoteDisconnect()
        appRemote.disconnect()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        self.connect();
    }

    func connect() {
        playerViewController.appRemoteConnecting()
        appRemote.connect()
    }

    // MARK: AppRemoteDelegate
    
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        self.appRemote = appRemote
        playerViewController.appRemoteConnected()
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        print("didFailConnectionAttemptWithError")
        playerViewController.appRemoteDisconnect()
    }
    
    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        print("didDisconnectWithError")
        playerViewController.appRemoteDisconnect()
    }

}
