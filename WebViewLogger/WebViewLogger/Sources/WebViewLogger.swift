//
//  WebViewLogger.swift
//  WebViewLogger
//
//  Created by Sreejith Rajan on 07/08/24.
//

import Foundation
import WebKit

public protocol WebViewLoggerDelegate: AnyObject {
    func didCaptureStatusValue(_ value: String)
}

public class WebViewLogger: NSObject, WKNavigationDelegate, WKScriptMessageHandler {

    public static let shared = WebViewLogger()

    public weak var delegate: WebViewLoggerDelegate?
    private let serialQueue = DispatchQueue(label: "com.webviewlogger.serialQueue")

    private override init() {
        super.init()
    }

    public func configureWebView(_ webView: WKWebView) {
        webView.navigationDelegate = self
        let contentController = webView.configuration.userContentController
        contentController.add(self, name: "logger")
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.documentElement.outerHTML.toString()") { [weak self] (html: Any?, error: Error?) in
            guard let self = self else { return }
            self.serialQueue.async {
                if let htmlString = html as? String {
                    self.logHTML(htmlString)
                    self.captureStatusValue(from: htmlString)
                } else if let error = error {
                    print("Error logging webview response: \(error.localizedDescription)")
                }
            }
        }
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "logger" else { return }
        serialQueue.async {
            if let body = message.body as? String {
                self.captureStatusValue(from: body)
            }
        }
    }

    private func logHTML(_ html: String) {
        // Customize logging logic here
        print("WebView HTML Response: \(html)")
    }

    private func captureStatusValue(from html: String) {
        // Assuming the response is a JSON string embedded in the HTML
        if let jsonData = html.data(using: .utf8) {
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                    if let status = jsonObject["status"] as? String {
                        print("Captured status value: \(status)")
                        DispatchQueue.main.async {
                            self.delegate?.didCaptureStatusValue(status)
                        }
                    } else {
                        print("Status key not found in the response.")
                    }
                } else {
                    print("Failed to parse JSON from HTML.")
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
            }
        } else {
            print("Failed to convert HTML to data.")
        }
    }
}
