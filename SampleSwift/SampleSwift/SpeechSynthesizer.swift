//
//  Copyright © 2019 Fairy Devices, Inc. All rights reserved.
//

import AVFoundation
import SwiftUI

var ttsResultWavData: Data?

class SpeechSynthesizer: NSObject, AVAudioPlayerDelegate {
    private var inputLang: String
    private var text: String
    private var gender: String
    private var ttsPlayer: AVAudioPlayer!
    private let semaphore = DispatchSemaphore(value: 0)
    
    init(inputLang: String, text: String, gender: String) {
        self.inputLang = inputLang
        self.text = text
        self.gender = gender
        super.init()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("audio player finished as : \(flag)")
        semaphore.signal()
    }
    
    func speechSynthesizer(callAPI: SpeechSynthesizer) {
        let session = URLSession.shared
        
        var urlComponents = URLComponents(string: "https://sandbox-ss.mimi.fd.ai/speech_synthesis")!
        urlComponents.queryItems = [
            URLQueryItem(name: "text", value: self.text.precomposedStringWithCanonicalMapping),
            URLQueryItem(name: "lang", value: self.inputLang),
            URLQueryItem(name: "engine", value: "nict"),
            URLQueryItem(name: "gender", value: self.gender)
        ]
        var httpRequest = URLRequest(url: urlComponents.url!)
        httpRequest.httpMethod = "GET"
        httpRequest.setValue("Bearer " + gAccessToken, forHTTPHeaderField: "Authorization")
        
        let task = session.dataTask(with: httpRequest) { data, response, error in
            // client error
            if let error = error {
                print("client error: \(error.localizedDescription) \n")
                return
            }
            
            guard let data = data, let response = response as? HTTPURLResponse else {
                print("no data or no response")
                return
            }
            
            if response.statusCode == 200 {
                print("success synthesize")
                ttsResultWavData = data
                do {
                    self.ttsPlayer = try AVAudioPlayer(data: data)
                    self.ttsPlayer.delegate = self
                    self.ttsPlayer.prepareToPlay()
                    self.ttsPlayer.play()
                    self.semaphore.wait()
                } catch {
                    print("synthesize error \(error)")
                    self.semaphore.signal()
                    return
                }
            } else {
                // レスポンスのステータスコードが200でない場合などはサーバサイドエラー
                print("server error status code: \(response.statusCode)\n")
                let responseData = String(data: data, encoding: String.Encoding.utf8)
                print("tts response :\(responseData!)")
            }
        }
        task.resume()
    }
}
