import Foundation
import SwiftyJSON

/// A memorized Access Token, with the ability to auto-refresh when needed.

public class AccessToken {
    
    fileprivate let path = "v1/security/oauth2/token"
  
    private let grant_type: String
    
    public var client_id: String
    public var client_secret:String
    
    // Store an access token and calculates the expiry date
    private var access_token: String
    private var expires_time: Int

    private var config: Configuration
    
    public init(client_id: String, client_secret:String, config:Configuration) {
        self.grant_type =  "client_credentials"
        self.client_id = client_id
        self.client_secret = client_secret
        self.expires_time = 0
        self.access_token = ""
        self.config = config
    }
    
    ///This method checks if the access_tocken needs to be renewed and, if needed, request the access_token,
    ///updates the token and save it, if you do not have to renew it returns the access_token that we had stored
    ///
    /// - Returns:
    ///     access_token: `String` the client access token
    public func get(onCompletion: @escaping (String) -> Void){
        if needRefresh() {
            fetchAuthToken(onCompletion: {
                access_token in
                 onCompletion(access_token)
            })
        } else {
            onCompletion(access_token)
        }
    }

    ///Checks if this access token needs a refresh.
    private func needRefresh() -> Bool{
        return (access_token == "" || access_token == "error" || Int(Date().timeIntervalSince1970 * 1000) > expires_time)
    }

    ///Fetches a new Access Token using the credentials from the client.
    private func fetchAuthToken(onCompletion: @escaping (String) -> Void){
        
        let body = "grant_type=" + grant_type + "&client_id=" + client_id + "&client_secret=" + client_secret
        let headers = ["Content-Type" : "application/x-www-form-urlencoded"]

        let url = self.config.baseURL + path

        _post(url:url, headers:headers, body:body, onCompletion: {
            (response, err) in
            
            if let error = response?.result["error"].string{
                onCompletion(error)
            }else{
                if let auth = response?.result["access_token"].string{
                    onCompletion(auth)
                }else{
                    onCompletion("error")
                }
            }
            self.storeData(data: response?.result ?? JSON())
        })
    }

    private func storeData(data: JSON){
        if let access_token = data["access_token"].string{
            self.access_token = access_token
        }else{
            self.access_token = "error"
        }
        
        if let expires_time = data["expires_in"].int{
            self.expires_time = expires_time * 1000 + Int(Date().timeIntervalSince1970 * 1000)
        }else{
            self.expires_time = 0
        }
    }
}