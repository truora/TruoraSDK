# Truora SDK

The Truora SDK is a Swift package that provides functionality to integrate Truora's Digital Identity (DI) and Government services into your iOS applications. This package includes classes and protocols to initiate identity processes and handle their results.

## Installation

You can install the Truora SDK via Swift Package Manager. Simply add the following line to your `Package.swift` file's dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/truora/TruoraSDK.git", from: "1.0.0")
]
```

## Digital Identity SDK

### Usage

1. Import the TruoraSDK module

    ```swift
      import TruoraSDK
    ```

2. Initialize TruoraSDK
  To start using the Truora SDK, initialize an instance of TruoraSDK, set its delegate and add it as a subview of your view.

    ```swift
    let truoraSDK = TruoraSDK(frame: view.bounds)
    truoraSDK.delegateDI = self

    view.addSubview(truoraSDK)
    ```

3. Load DI Frontend
  Load the DI frontend using the LoadDI method. You need to provide a LoadFrontendInput object with your API token.

    ```swift
    let input = LoadFrontendInput(token: "YOUR_TOKEN_HERE")
    do {
        try truoraSDK.LoadDI(input: input)
    } catch let error {
        print("Error: \(error)")
    }
    ```

4. Implement Delegate Methods
  Implement the TruoraSDKDIDelegate protocol methods to handle events and errors.

    ```swift
    extension YourViewController: TruoraSDKDIDelegate {
        func close() {
            // Handle close event
            truoraSDK.removeFromSuperview() // Recomended if it was added as a subview
        }

        func handleError(error: TruoraError) {
            // Handle error
        }

        func stepsCompleted(result: TruoraResultDI) {
            // Handle steps completed event
        }

        func processSucceeded(result: TruoraResultDI) {
            // Handle process succeeded event
        }

        func processFailed(result: TruoraResultDI) {
            // Handle process failed event
        }
    }
    ```

### Structures

#### LoadFrontendInput

The LoadFrontendInput struct represents the input parameters required to use the Truora SDK.

```swift
public struct LoadFrontendInput {
    public var token: String = ""

    public init(token: String) {
        self.token = token
    }
}
```

#### TruoraSDKDIDelegate

The TruoraSDKDIDelegate protocol defines methods for handling Di processes events and errors.

```swift
public protocol TruoraSDKDIDelegate: NSObjectProtocol {
    func close()
    func handleError(error: TruoraError)
    func stepsCompleted(result: TruoraResultDI)
    func processSucceeded(result: TruoraResultDI)
    func processFailed(result: TruoraResultDI)
}
```

#### TruoraResultDI

The TruoraResultDI struct represents the values returned from a DI process.

```swift
public struct TruoraResultDI : Codable {
    public var processID: String = ""
}
```

#### TruoraSDK

The TruoraSDK class provides a method to load the DI frontend.

```swift
public class TruoraSDK: UIView, WKScriptMessageHandler {
    public weak var delegateDI: TruoraSDKDIDelegate?

    public func LoadDI(input: LoadFrontendInput) throws {
        // Load DI frontend through Truora SDK
    }
}
```

#### Error Handling

The Truora SDK throws errors of type TruoraError during the capture or processing.

- `TruoraError.MissingToken`: Thrown when the token is not provided.
- `TruoraError.InternalError`: Thrown when an unexpected error occurs.

#### Important Notes

- Ensure that you handle callback events appropriately using the provided delegates.
Check for errors thrown by the SDK methods and handle them accordingly.
- This SDK requires an API token obtained from Truora.

For more information, refer to the official Truora documentation.

## Government

Comming soon...

## License

This SDK is provided under the MIT License. See the LICENSE file for details.
