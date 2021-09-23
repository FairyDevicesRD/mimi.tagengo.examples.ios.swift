//
//  Copyright © 2019 Fairy Devices, Inc. All rights reserved.
//

import SwiftUI

private enum GetTokenError: Error {
    case jsonParse(String)
    case responseData(String)
}

class AccessTokenGetter {
    private var grantType: String
    private var clientId: String
    private var clientSecret: String
    private var scope: String
    private var accessToken: String
    private let session: URLSession
    
    init(grantType: String, clientId: String, clientSecret: String, scope: String) {
        self.grantType = grantType
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.scope = scope
        accessToken = ""
        session = URLSession.shared
    }
    
    func execute() -> (String) {
        var gotAccessToken: String = ""
        
        var urlComponents = URLComponents(string: "https://auth.mimi.fd.ai/v2/token")!
        urlComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: self.grantType),
            URLQueryItem(name: "client_id", value: self.clientId),
            URLQueryItem(name: "client_secret", value: self.clientSecret),
            URLQueryItem(name: "scope", value: self.scope)
        ]
        var httpRequest = URLRequest(url: urlComponents.url!)
        httpRequest.httpMethod = "POST"
        let semaphore = DispatchSemaphore(value: 0)
        let task = session.dataTask(with: httpRequest) { data, response, error in
            
            if let error = error {
                print("client error: \(error.localizedDescription)")
                return
            }
            guard let data = data, let response = response as? HTTPURLResponse else {
                print("no data or no response")
                return
            }
            if response.statusCode == 200 {
                print("get access token success")
                do {
                    guard let responseJson = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: Any] else {
                        print("json convert failed")
                        return
                    }
                    if let baseAccessToken = responseJson["accessToken"] as? String {
                        self.accessToken = baseAccessToken
                        gotAccessToken = self.accessToken
                        print("got access token:" + self.accessToken)
                    }
                    semaphore.signal()
                    
                } catch {
                    print("Serialize Error")
                    return
                }
            } else {
                let responseData = String(data: data, encoding: String.Encoding.utf8)
                print("server error status code: \(response.statusCode) , response data: \(responseData!)")
            }
        }
        task.resume()
        _ = semaphore.wait()
        
        return gotAccessToken
    }
    
    func getAccesstokenText() -> String {
        accessToken
    }
}

func executeAccessTokenGetter() -> String {
    let accessTokenGetter: AccessTokenGetter = AccessTokenGetter(
        grantType: "https://auth.mimi.fd.ai/grant_type/application_credentials",
        clientId: appId,
        clientSecret: secret,
        scope: scope
    )
    var accessToken: String
    
    accessToken = accessTokenGetter.execute()
    return accessToken
}
