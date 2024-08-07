# WebViewLogger

`WebViewLogger` is a Swift framework designed to capture and log HTML responses from `WKWebView`. It provides a simple way to handle and log web content, making it easier to debug and analyze web interactions in your iOS applications. The framework includes methods to capture specific status values from JSON responses embedded in HTML.

## Features

- **Singleton Design**: Ensures a single instance of `WebViewLogger` throughout the application.
- **Delegate Protocol**: `WebViewLoggerDelegate` allows capturing specific status values from web view responses.
- **Thread-Safe**: Uses a serial dispatch queue to handle web view responses, ensuring thread safety.
- **Easy Configuration**: Simple method to set up message handling and navigation delegation for `WKWebView`.

## Installation

### CocoaPods

1. Add the following to your `Podfile`:
    ```ruby
    target 'YourAppTarget' do
      pod 'WebViewLogger', :path => '../path/to/WebViewLogger'
    end
    ```
2. Run `pod install`.

### Swift Package Manager

1. Add the package to your `Package.swift`:
    ```swift
    dependencies: [
        .package(url: "https://github.com/yourusername/WebViewLogger.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourAppTarget",
            dependencies: ["WebViewLogger"]
        )
    ]
    ```

### Carthage

1. Add the following to your `Cartfile`:
    ```ruby
    github "yourusername/WebViewLogger" ~> 1.0
    ```
2. Run `carthage update`.

## Usage

### Basic Setup

1. **Configure the `WKWebView`**:
    ```swift
    import WebKit
    import WebViewLogger

    class ViewController: UIViewController, WebViewLoggerDelegate {
        var webView: WKWebView!

        override func viewDidLoad() {
            super.viewDidLoad()
            webView = WKWebView(frame: self.view.frame)
            WebViewLogger.shared.configureWebView(webView)
            WebViewLogger.shared.delegate = self
            self.view.addSubview(webView)
        }

        // Implement WebViewLoggerDelegate method
        func didCaptureStatusValue(_ value: String) {
            print("Captured status: \(value)")
        }
    }
    ```

2. **Load a URL in `WKWebView`**:
    ```swift
    webView.load(URLRequest(url: URL(string: "https://example.com")!))
    ```

## Test Cases

### Test Logging HTML Response

```swift
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

## Data Race Condition Mitigation

The `WebViewLogger` class uses a serial dispatch queue to ensure thread safety and prevent data race conditions. The `serialQueue` ensures that logging and capturing key-value pairs from the `WKWebView` responses are done sequentially.

```swift
private let serialQueue = DispatchQueue(label: "com.webviewlogger.serialQueue")

// Usage within class methods
serialQueue.async {
    // Thread-safe code
}

Contributing
Fork the repository.
Create your feature branch (git checkout -b feature/my-new-feature).
Commit your changes (git commit -am 'Add some feature').
Push to the branch (git push origin feature/my-new-feature).
Create a new Pull Request.
License
This project is licensed under the MIT License - see the LICENSE.md file for details.

Acknowledgments
Inspired by real-world use cases of logging and handling WKWebView responses.
Thanks to all the developers and contributors who helped in testing and improving this class.
