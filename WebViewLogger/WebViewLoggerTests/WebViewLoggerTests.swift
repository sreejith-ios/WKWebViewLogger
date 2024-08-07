//
//  WebViewLoggerTests.swift
//  WebViewLoggerTests
//
//  Created by Sreejith Rajan on 07/08/24.
//

import XCTest
import WebKit
@testable import WebViewLogger

class WebViewLoggerTests: XCTestCase, WebViewLoggerDelegate {

    var webView: WKWebView!
    var expectations: [XCTestExpectation] = []

    override func setUpWithError() throws {
        webView = WKWebView()
        WebViewLogger.shared.configureWebView(webView)
        WebViewLogger.shared.delegate = self
    }

    override func tearDownWithError() throws {
        webView = nil
        expectations = []
    }

    func testLoggingHTMLResponse() throws {
        let expectation = self.expectation(description: "Logging HTML Response")
        expectations.append(expectation)

        let testHTML = """
        <html>
        <head><title>Test</title></head>
        <body>
        <script>
        window.webkit.messageHandlers.logger.postMessage(document.documentElement.outerHTML);
        </script>
        </body>
        </html>
        """

        webView.loadHTMLString(testHTML, baseURL: nil)

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testCapturingStatusValue() throws {
        let expectation = self.expectation(description: "Capturing Status Value")
        expectations.append(expectation)

        let testHTML = """
        <html>
        <head><title>Test</title></head>
        <body>
        <script>
        window.webkit.messageHandlers.logger.postMessage('{"status": "success"}');
        </script>
        </body>
        </html>
        """

        webView.loadHTMLString(testHTML, baseURL: nil)

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testInvalidJSONResponse() throws {
        let expectation = self.expectation(description: "Handling Invalid JSON Response")
        expectations.append(expectation)

        let testHTML = """
        <html>
        <head><title>Test</title></head>
        <body>
        <script>
        window.webkit.messageHandlers.logger.postMessage('Invalid JSON');
        </script>
        </body>
        </html>
        """

        webView.loadHTMLString(testHTML, baseURL: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testHandlingMultipleURLs() throws {
        let numberOfURLs = 5
        for i in 1...numberOfURLs {
            let expectation = self.expectation(description: "Handling URL \(i)")
            expectations.append(expectation)

            let testHTML = """
            <html>
            <head><title>Test \(i)</title></head>
            <body>
            <script>
            window.webkit.messageHandlers.logger.postMessage('{"status": "success \(i)"}');
            </script>
            </body>
            </html>
            """

            DispatchQueue.global().async {
                self.webView.loadHTMLString(testHTML, baseURL: nil)
            }
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func didCaptureStatusValue(_ value: String) {
        XCTAssertTrue(value.starts(with: "success"))

        // Find the expectation that matches this status value and fulfill it
        if let expectation = expectations.first(where: { value.contains("\($0.description.split(separator: " ").last!)") }) {
            expectation.fulfill()
        }
    }
}
