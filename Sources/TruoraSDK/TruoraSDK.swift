import UIKit
import WebKit

/// Possible errors returned in the functions that throw
public enum TruoraError: Error {
    /// MissingValidationID validation id was not provided
    case MissingValidationID
    /// InternalError internal error ocurred during the capture
    /// or processing
    case InternalError
    /// MissingToken token was not provided
    case MissingToken
}

/// Represents the values returned from a Validation
public struct TruoraResult : Codable {
    // Status of the validation
    public var status: Status = ""
    // ValidationID provided
    public var validationID: String = ""
}

/// Represents the values returned from a DI process
public struct TruoraResultDI : Codable {
    // processID of the process
    public var processID: String = ""
}

/// Status of a truora result
public typealias Status = String

/// TruoraEvent of an identity process
public typealias TruoraEvent = String

/// The validation succeeded
public let STATUS_SUCCEEDED: Status = "succeeded"
/// The validation failed either from liveness or face match
public let STATUS_FAILED: Status = "failed"
private let STATUS_PENDING: Status = "pending"

/// The identity process succeeded event
public let PROCESS_SUCCEEDED: TruoraEvent = "truora.process.succeeded"
/// The identity process failed event
public let PROCESS_FAILED: TruoraEvent = "truora.process.failed"
/// The identity process steps completed event
public let STEPS_COMPLETED: TruoraEvent = "truora.steps.completed"

/// Language to be used
public typealias Language = String

/// ES language
public let LANGUAGE_ES: Language = "es"

/// Input provided to use the Load DI front
public struct LoadFrontendInput {
    /// API key to load DI front
    public var token: String = ""

    public init(token: String) {
        self.token = token
    }
}

/// Input provided to use the SDK
public struct TruoraInput {
    /// language to use, defaults to ES
    public var language: Language = LANGUAGE_ES
    /// If not empty the document number view
    /// will not be shown to the end user
    /// this parameter is not validated it
    public var documentNumber: String = ""
    /// validationID obtained from the backend
    public var validationID: String = ""
    /// callback that recieves the TruoraResult
    /// once a validation has finished
    public var onComplete: ((TruoraResult) -> Void)
    /// callback that recieves the TruoraResult
    /// once a validation has expired
    public var onExpired: ((TruoraResult) -> Void)

    public init(documentNumber: String, validationID: String, language: Language,
                onComplete: @escaping ((TruoraResult) -> Void), onExpired:  @escaping ((TruoraResult) -> Void)) {
        self.documentNumber = documentNumber
        self.validationID = validationID
        self.onComplete = onComplete
        self.onExpired = onExpired
        self.language = language
    }
}

private let onCompletePrefix: String = "onComplete:"
private let onExpiredPrefix: String = "onExpired:"
private let baseURL: String = "https://sdk.truorastaging.com/"
private let identityURL: String = "https://identity.truora.com?token="

public protocol TruoraSDKDIDelegate: NSObjectProtocol {
    /// method to close the TruoraSDK view
    func close()
    /// method to handle errors
    func handleError(error: TruoraError)
    /// method that recieves the TruoraEvent
    /// once the identity process steps are completed
    func stepsCompleted(result: TruoraResultDI)
    /// method that recieves the TruoraEvent
    /// once an identity process is succeeded
    func processSucceeded(result: TruoraResultDI)
    /// method that recieves the TruoraEvent
    /// once an identity process is failed
    func processFailed(result: TruoraResultDI)
}

/// Class to start the Truora SDK
public class TruoraSDK: UIView, WKScriptMessageHandler {
    private var webView: WKWebView!
    private var input: TruoraInput?
    private var loadFrontendInput: LoadFrontendInput?
    public weak var delegateDI: TruoraSDKDIDelegate?

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    /// Starts the Truora SDK
    /// - Parameter input: represents the TruoraInput
    /// - Throws: `TruoraError.MissingValidationID` if the validationID is not provided.
    /// - Throws: `TruoraError.InternalError` if an unexpected error ocurred.
    public func Start(input: TruoraInput) throws {
        if input.validationID == "" {
            throw TruoraError.MissingValidationID
        }

        self.input = input

        do {
            try setupWebView()
        } catch {
            throw TruoraError.InternalError
        }
    }

    /// Load DI frontend through the Truora SDK
    /// - Parameter input: represents the TruoraInput
    /// - Throws: `TruoraError.MissingToken` if the token is not provided.
    /// - Throws: `TruoraError.InternalError` if an unexpected error ocurred.
    public func LoadDI(input: LoadFrontendInput) throws {
        if input.token == "" {
            throw TruoraError.MissingToken
        }

        self.loadFrontendInput = input

        do {
            try setupDIFrontend(token: input.token)
        } catch {
            throw TruoraError.InternalError
        }
    }

    private func setupDIFrontend(token: String) throws {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.requiresUserActionForMediaPlayback = false
        configuration.userContentController.add(self, name: "WebViewSDK")

        webView = WKWebView(frame: bounds, configuration: configuration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        if #available(iOS 16.4, *) {
           webView.isInspectable = true
        }

        addSubview(webView)

        let processURL = URL(string: identityURL + token)
        let request = URLRequest(url: processURL!)
        webView.load(request)
    }

    private func setupWebView() throws {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.requiresUserActionForMediaPlayback = false
        configuration.userContentController.add(self, name: "callbackHandler")

        webView = WKWebView(frame: bounds, configuration: configuration)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if #available(iOS 16.4, *) {
           webView.isInspectable = true
        }

        addSubview(webView)

        guard let inputValue = self.input else {
            throw TruoraError.InternalError
        }

        let html = """
            <!DOCTYPE html>
            <html lang="en">
              <head>
                <meta charset="UTF-8" />
                <link rel="icon" href="/favicon.png" />
                <script type="module" src="/truorasdk.js"></script>
                <link rel="stylesheet" crossorigin href="/truorasdk.css">
                <meta name="viewport" content="width=device-width, initial-scale=1.0" />
                <title>Truora SDK</title>
              </head>
              <body onload="loadSDK()">
                <div id="app">
                </div>
              </body>
              <script>
                console.error(window.TruoraSDK)
                const loadSDK = () => {
                   window.TruoraSDK.init({
                    element_id: "app",
                    validation_id: "\(inputValue.validationID)",
                    document_number: "\(inputValue.documentNumber)",
                    lang: "\(inputValue.language)",
                    on_complete: (result) => {
                      window.webkit.messageHandlers.callbackHandler.postMessage( "\(onCompletePrefix)"+ JSON.stringify(result));
                    },
                    on_expired: (result) => {
                      window.webkit.messageHandlers.callbackHandler.postMessage( "\(onCompletePrefix)"+ JSON.stringify(result));
                    },
                  });
                };
              </script>
            </html>
        """

        webView.loadHTMLString(html, baseURL: URL(string: baseURL))
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let messageBody = message.body as? String else { return }

        guard let inputValue = self.input else {
            guard let loadFrontendInputValue = self.loadFrontendInput, let delegate = delegateDI else {
                return
            }

            setCallbackLoadDI(messageName: message.name, messageBody: messageBody, delegate: delegate)
            return
        }

        var messageStr = ""
        var callBack = inputValue.onComplete

        if messageBody.hasPrefix(onCompletePrefix) {
            messageStr = removePrefix( prefix: onCompletePrefix, string: messageBody)
            callBack = inputValue.onComplete
        }

        if messageBody.hasPrefix(onExpiredPrefix) {
            messageStr = removePrefix( prefix: onExpiredPrefix, string: messageBody)
            callBack = inputValue.onExpired
        }

        if messageStr == "" {
            print("Invalid message recieved")
            return
        }

        if let jsonData = messageStr.data(using: .utf8) {
            do {
                let decoder = JSONDecoder()

                let result = try decoder.decode(TruoraResult.self, from: jsonData)

                callBack(result)
            } catch {
                print("Error decoding JSON: \(error)")
                return
            }
        }
    }
}

private func removePrefix(prefix: String, string: String) -> String {
    return String(string.dropFirst(prefix.count))
}

private func setCallbackLoadDI(messageName: String, messageBody: String, delegate: TruoraSDKDIDelegate) -> Void {
    guard messageName == "WebViewSDK" else {
        return
    }

    let messageParts = messageBody.components(separatedBy: ",")
    guard messageParts.count == 2 else {
        delegate.handleError(error: TruoraError.InternalError)
        delegate.close()
        return
    }

    let event: String = messageParts[0]
    let processID = messageParts[1]

    var messageStr = ""

    if event == STEPS_COMPLETED {
        messageStr = STEPS_COMPLETED
        delegate.stepsCompleted(result: TruoraResultDI(processID: processID))
    }

    if event == PROCESS_SUCCEEDED {
        messageStr = PROCESS_SUCCEEDED
        delegate.processSucceeded(result: TruoraResultDI(processID: processID))
    }

    if event == PROCESS_FAILED {
        messageStr = PROCESS_FAILED
        delegate.processFailed(result: TruoraResultDI(processID: processID))
    }

    if messageStr == "" {
        print("Invalid message recieved")
        delegate.handleError(error: TruoraError.InternalError)
    }

    delegate.close()
}
