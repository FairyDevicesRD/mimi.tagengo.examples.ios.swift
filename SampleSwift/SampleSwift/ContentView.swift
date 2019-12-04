//
//  Copyright © 2019 Fairy Devices, Inc. All rights reserved.
//

import AVFoundation
import SwiftUI

let appId: String = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" // FIXME:
let secret: String = "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" // FIXME:
let scope: String = "https://apis.mimi.fd.ai/auth/asr/websocket-api-service;https://apis.mimi.fd.ai/auth/asr/http-api-service;https://apis.mimi.fd.ai/auth/nict-asr/websocket-api-service;https://apis.mimi.fd.ai/auth/nict-asr/http-api-service;https://apis.mimi.fd.ai/auth/nict-tra/http-api-service;https://apis.mimi.fd.ai/auth/nict-tts/http-api-service;https://apis.mimi.fd.ai/auth/google-asr/http-api-service;https://apis.mimi.fd.ai/auth/google-asr/websocket-api-service"
var audioEngine: AVAudioEngine!
var gAccessToken: String = ""
private var nowRecording: Bool = false
var asrClient: ASRClient?

private let processSettings = [
    "nict-asr"
]

private let genderSettings = [
    "male",
    "female",
    "unknown"
]

private let languageSettings = [
    "ja",
    "en",
    "zh",
    "ko",
    "id",
    "my",
    "th",
    "vi",
    "fr",
    "es"
]

struct ContentView: View {
    private var titleRow = TitleRowView()
    
    @State private var asrBtnLabel = "音声認識"
    @State private var ttsText: String = ""
    @State private var traText: String = ""
    @State private var traResult: String = "＜機械翻訳結果を表示します＞"
    @State private var asrResult: String = "＜音声認識結果を表示します＞"
    
    @State private var processChoiceIndex: Int = 0
    @State private var languageChoiceIndexAsr: Int = 0
    @State private var languageChoiceIndexTraSource: Int = 0
    @State private var languageChoiceIndexTraTarget: Int = 1
    @State private var languageChoiceIndexTts: Int = 1
    @State private var genderChoiceIndex: Int = 0
    
    init() {
        gAccessToken = executeAccessTokenGetter()
        Timer.scheduledTimer(withTimeInterval: 60 * 20, repeats: true) { _ in
            gAccessToken = executeAccessTokenGetter()
        }
        
        audioEngine = AVAudioEngine()
        asrClient = ASRClient()
    }
    
    var body: some View {
        VStack {
            titleRow
            Spacer()
            
            ScrollView(.vertical) {
                VStack {
                    Text(self.asrResult)
                        .font(Font.system(size: 26))
                    
                    Text("input Language")
                        .multilineTextAlignment(.leading)
                    Picker("Options", selection: $languageChoiceIndexAsr) {
                        ForEach(0 ..< languageSettings.count) { index in
                            Text(languageSettings[index]).tag(index)
                        }
                        
                    }.pickerStyle(SegmentedPickerStyle())
                    
                    Text("process").multilineTextAlignment(.leading)
                    
                    Picker("Options", selection: $processChoiceIndex) {
                        ForEach(0 ..< processSettings.count) { index in
                            Text(processSettings[index]).tag(index)
                        }
                        
                    }.pickerStyle(SegmentedPickerStyle())
                    
                    Button(action: {
                        if nowRecording {
                            print("stop recording")
                            self.asrBtnLabel = "音声認識"
                            nowRecording = false
                            audioEngine.stop()
                            audioEngine.inputNode.removeTap(onBus: 0)
                            recordingFinish(asrResultText: &self.asrResult)
                        } else {
                            print("start recording")
                            self.asrBtnLabel = "録音停止"
                            nowRecording = true
                            asrClient?.connect()
                            directRecording(targetProcess: processSettings[self.processChoiceIndex], targetLanguage: languageSettings[self.languageChoiceIndexAsr])
                        }
                    }, label: { Text(self.asrBtnLabel).font(.title) })
                    
                    Button(action: {
                        self.traText = self.asrResult
                    }, label: { Text("↓結果を次の入力にする").font(.title) })
                }
                
                Spacer()
                
                VStack {
                    Text("source Language")
                    Picker("Options", selection: $languageChoiceIndexTraSource) {
                        ForEach(0 ..< languageSettings.count) { index in
                            Text(languageSettings[index]).tag(index)
                        }
                    }.pickerStyle(SegmentedPickerStyle())
                    
                    Text("distination Language")
                    Picker("Options", selection: $languageChoiceIndexTraTarget) {
                        ForEach(0 ..< languageSettings.count) { index in
                            Text(languageSettings[index]).tag(index)
                        }
                    }.pickerStyle(SegmentedPickerStyle())
                    
                    VStack {
                        TextField("翻訳する文章を入力", text: $traText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(alignment: Alignment.center)
                    }
                    Text("\(traResult)").font(Font.system(size: 26))
                    
                    Button(action: {
                        let tra: Translator = Translator(
                            sourceLang: languageSettings[self.languageChoiceIndexTraSource],
                            text: self.traText,
                            targetLang: languageSettings[self.languageChoiceIndexTraTarget]
                        )
                        _ = tra.translate()
                        self.traResult = tra.resultText
                    }, label: { Text("機械翻訳").font(.title) })
                    
                    Button(action: {
                        self.ttsText = self.traResult
                    }, label: { Text("↓結果を次の入力にする").font(.title) })
                }
                
                Spacer()
                
                VStack {
                    TextField("読み上げる文章を入力", text: self.$ttsText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(alignment: Alignment.center)
                    
                    Text("input Language").multilineTextAlignment(.leading)
                    Picker("Options", selection: $languageChoiceIndexTts) {
                        ForEach(0 ..< languageSettings.count) { index in
                            Text(languageSettings[index]).tag(index)
                        }
                    }.pickerStyle(SegmentedPickerStyle())
                    
                    Text("gender").multilineTextAlignment(.leading)
                    Picker("Options", selection: $genderChoiceIndex) {
                        ForEach(0 ..< genderSettings.count) { index in
                            Text(genderSettings[index]).tag(index)
                        }
                    }.pickerStyle(SegmentedPickerStyle())
                    
                    Button(action: {
                        let tts: SpeechSynthesizer = SpeechSynthesizer(
                            inputLang: languageSettings[self.languageChoiceIndexTts],
                            text: self.ttsText,
                            gender: genderSettings[self.genderChoiceIndex]
                        )
                        tts.speechSynthesizer(callAPI: tts)
                    }, label: { Text("音声合成").font(.title) })
                }
                
                Spacer()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
