//
//  Copyright © 2019 Fairy Devices, Inc. All rights reserved.
//

import SwiftUI

import AVFoundation
import Foundation
import Starscream

class ASRClient: WebSocketConnectionDelegate {
    private let webSocketTaskConnection: WebSocketTaskConnection
    var resultText: String
    private var resultJson: [String: Any]?
    private var targetProcess: String
    private var targetLanguage: String
    var isWorking: Bool = false
    private var isReceiving: Bool = false
    
    init(targetProcess: String = "asr", targetLanguage: String = "ja") {
        self.targetProcess = targetProcess
        self.targetLanguage = targetLanguage
        
        var urlRequest = URLRequest(url: URL(string: "wss://sandbox-sr.mimi.fd.ai")!)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("Bearer " + gAccessToken, forHTTPHeaderField: "Authorization")
        urlRequest.setValue(targetProcess, forHTTPHeaderField: "x-mimi-process")
        urlRequest.setValue(targetLanguage, forHTTPHeaderField: "x-mimi-input-language")
        urlRequest.setValue("audio/x-pcm;bit=16;rate=16000;channels=1", forHTTPHeaderField: "Content-Type")
        
        webSocketTaskConnection = WebSocketTaskConnection(urlrequest: urlRequest)
        webSocketTaskConnection.connect()
        resultText = ""
        
        webSocketTaskConnection.delegate = self
    }
    
    func onConnected(connection: WebSocketConnection) {
        print("asr client connected")
        isWorking = true
    }
    
    func onDisconnected(connection: WebSocketConnection, error: Error?) {
        if let error = error {
            print("asr client disconnected with error:\(error)")
        } else {
            print("asr client disconnected normally")
        }
        sleep(2)
        isWorking = false
    }
    
    func onError(connection: WebSocketConnection, error: Error) {
        print("asr client connection error:\(error)")
        sleep(2)
        isWorking = false
    }
    
    func onMessage(connection: WebSocketConnection, text: String) {
        resultText = ""
        do {
            let responseJson: [String: Any]? = try JSONSerialization.jsonObject(
                with: text.data(using: .utf8)!,
                options: JSONSerialization.ReadingOptions.allowFragments
            ) as? [String: Any]
            guard let responseStatus: String = responseJson?["status"] as? String else {
                print("json key doesn't exist")
                return
            }
            if responseStatus == "recog-finished" {
                isWorking = false
            }
            if ["asr", "google-asr"].firstIndex(of: targetProcess) != nil {
                let response = responseJson?["response"] as? [[String: Any]]
                for res in response! {
                    if let baseResultText = res["result"] as? String {
                        resultText += baseResultText
                    }
                }
                
            } else if targetProcess == "nict-asr" {
                let response = responseJson?["response"] as? [[String: Any]]
                for res in response! {
                    if let resultRawString = res["result"] as? String {
                        let resultSeparated = resultRawString.components(separatedBy: "|")
                        resultText += resultSeparated[0]
                    }
                }
            }
            resultJson = responseJson
            isReceiving = false
        } catch {
            print("json serialize failed")
            return
        }
    }
    
    func onMessage(connection: WebSocketConnection, data: Data) {
        print("asr client Data message: \(data)")
    }
    
    func connect() {
        webSocketTaskConnection.connect()
    }
    
    func send(data: Data) {
        webSocketTaskConnection.send(data: data)
    }
    
    func send(text: String) {
        webSocketTaskConnection.send(text: text)
    }
}

func directRecording(targetProcess: String, targetLanguage: String) {
    asrClient = ASRClient(targetProcess: targetProcess, targetLanguage: targetLanguage)
    asrClient?.connect()
    
    let format: AVAudioFormat = AVAudioFormat(
        commonFormat: .pcmFormatFloat32,
        sampleRate: 44100,
        channels: 1,
        interleaved: true
    )!
    
    let downFormat: AVAudioFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 16000.0,
        channels: 1,
        interleaved: true
    )!
    
    let inputNode = audioEngine.inputNode
    inputNode.installTap(onBus: 0, bufferSize: AVAudioFrameCount(format.sampleRate * 0.4), format: nil) { (buffer: AVAudioPCMBuffer!, _: AVAudioTime!) in
        
        let converter = AVAudioConverter(from: format, to: downFormat)
        let newbuffer: AVAudioPCMBuffer = AVAudioPCMBuffer(pcmFormat: downFormat,
                                                           frameCapacity: AVAudioFrameCount(downFormat.sampleRate * 0.4))!
        let inputBlock: AVAudioConverterInputBlock = { (_, outStatus) -> AVAudioBuffer? in
            outStatus.pointee = AVAudioConverterInputStatus.haveData
            let audioBuffer: AVAudioBuffer = buffer
            return audioBuffer
        }
        var error: NSError?
        converter?.convert(to: newbuffer, error: &error, withInputFrom: inputBlock)
        if let err = error {
            print("error : \(err))")
        }
        // asr実行クラスの書き込み処理関数を呼び出し実行する。
        asrClient?.send(data: toData(PCMBuffer: newbuffer))
    }
    
    audioEngine.prepare()
    
    do {
        // エンジンを開始
        try audioEngine.start()
    } catch {
        print("engine.start() error:", error)
    }
}

func recordingFinish(asrResultText: inout String) {
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: ["command": "recog-break"], options: [])
        asrClient?.send(text: String(bytes: jsonData, encoding: .utf8)!)
        while asrClient!.isWorking {
            sleep(1)
            asrResultText = asrClient!.resultText
        }
        
    } catch {
        print("finish error: \(error)")
    }
}
