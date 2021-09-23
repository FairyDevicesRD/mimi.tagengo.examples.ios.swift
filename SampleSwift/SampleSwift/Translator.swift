//
//  Copyright © 2019 Fairy Devices, Inc. All rights reserved.
//

import SwiftUI

class Translator {
    private var sourceLang: String
    private var text: String
    private var targetLang: String
    var resultText: String = ""
    
    init(sourceLang: String, text: String, targetLang: String) {
        self.sourceLang = sourceLang
        self.text = text
        self.targetLang = targetLang
    }
    
    func translate() -> String {
        let session = URLSession.shared
        var translateResultText: String = ""
        
        var urlComponents = URLComponents(string: "https://sandbox-mt.mimi.fd.ai/machine_translation")!
        urlComponents.queryItems = [
            URLQueryItem(name: "text", value: self.text.precomposedStringWithCanonicalMapping),
            URLQueryItem(name: "source_lang", value: self.sourceLang),
            URLQueryItem(name: "target_lang", value: self.targetLang)
        ]
        var httpRequest = URLRequest(url: urlComponents.url!)
        httpRequest.httpMethod = "POST"
        httpRequest.setValue("Bearer " + gAccessToken, forHTTPHeaderField: "Authorization")
        httpRequest.httpBody = urlComponents.percentEncodedQuery?.data(using: .utf8)
        let semaphore = DispatchSemaphore(value: 0)
        let task = session.dataTask(with: httpRequest) { data, response, error in
            if let error = error {
                print("client error: \(error.localizedDescription) \n")
                semaphore.signal()
                return
            }
            
            guard let data = data, let response = response as? HTTPURLResponse else {
                print("no data or no response")
                semaphore.signal()
                return
            }
            
            if response.statusCode == 200 {
                print("success translate")
                self.resultText = String(data: data, encoding: .utf8) ?? "no result text"
                if let range = self.resultText.range(of: "[\"") {
                    self.resultText.replaceSubrange(range, with: "")
                }
                if let range = self.resultText.range(of: "\"]") {
                    self.resultText.replaceSubrange(range, with: "")
                }
                self.resultText = self.resultText.decodingUnicodeCharacters
                translateResultText = String(data: data, encoding: .utf8) ?? "no result text"
                semaphore.signal()
                
            } else {
                print("server error status code: \(response.statusCode)\n")
                let responseData = String(data: data, encoding: String.Encoding.utf8)
                print(responseData!)
                semaphore.signal()
            }
        }
        task.resume()
        _ = semaphore.wait()
        return translateResultText.decodingUnicodeCharacters
    }
}

extension String {
    var decodingUnicodeCharacters: String { applyingTransform(.init("Hex-Any"), reverse: false) ?? "" }
}
