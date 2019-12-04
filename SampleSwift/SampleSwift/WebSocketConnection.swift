//
//  Copyright © 2019 Fairy Devices, Inc. All rights reserved.
//

import Combine
import Foundation

/*
 WebSocketConnection
 WebSocket接続処理用のプロトコル
 自身の移譲先インスタンスの型にWebSocketConnectionDelegateを指定
 */
protocol WebSocketConnection {
    func send(text: String)
    func send(data: Data)
    func connect()
    func disconnect()
    var delegate: WebSocketConnectionDelegate? {
        get
        set
    }
}

/*
 WebSocketConnectionDelegate
 WebSocket接続処理　移譲用のプロトコル
 */
protocol WebSocketConnectionDelegate: AnyObject {
    func onConnected(connection: WebSocketConnection)
    func onDisconnected(connection: WebSocketConnection, error: Error?)
    func onError(connection: WebSocketConnection, error: Error)
    func onMessage(connection: WebSocketConnection, text: String)
    func onMessage(connection: WebSocketConnection, data: Data)
}

/*
 WebSocketTaskConnection
 urlSession : URLSessionWebSocketDelegateを継承し、URLSessionの移譲先に自身を指定することでURLSessionの受けたイベント発火の非同期処理完了通知を自身が受けることになる
 webSocketTask : URLSessionで受けたらURLlSessionWebSocketTaskで処理するように実装
 */
class WebSocketTaskConnection: NSObject, WebSocketConnection, URLSessionWebSocketDelegate {
    weak var delegate: WebSocketConnectionDelegate?
    var webSocketTask: URLSessionWebSocketTask!
    var urlSession: URLSession!
    let delegateQueue = OperationQueue()
    
    init(urlrequest: URLRequest) {
        super.init()
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: delegateQueue)
        webSocketTask = urlSession.webSocketTask(with: urlrequest)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        delegate?.onConnected(connection: self)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        delegate?.onDisconnected(connection: self, error: nil)
    }
    
    func connect() {
        webSocketTask.resume()
        
        listen()
    }
    
    func disconnect() {
        webSocketTask.cancel(with: .goingAway, reason: nil)
    }
    
    func listen() {
        webSocketTask.receive { result in
            switch result {
            case let .failure(error):
                self.delegate?.onError(connection: self, error: error)
            case let .success(message):
                switch message {
                case let .string(text):
                    self.delegate?.onMessage(connection: self, text: text)
                case let .data(data):
                    self.delegate?.onMessage(connection: self, data: data)
                @unknown default:
                    fatalError()
                }
                self.listen()
            }
        }
    }
    
    func send(text: String) {
        webSocketTask.send(URLSessionWebSocketTask.Message.string(text)) { error in
            if let error = error {
                self.delegate?.onError(connection: self, error: error)
            }
        }
    }
    
    func send(data: Data) {
        webSocketTask.send(URLSessionWebSocketTask.Message.data(data)) { error in
            if let error = error {
                self.delegate?.onError(connection: self, error: error)
            }
        }
    }
}
