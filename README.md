# Live Caller ID Lookup Example

[Live Caller ID
Lookup](https://developer.apple.com/documentation/sms_and_call_reporting/getting_up-to-date_calling_and_blocking_information_for_your_app)
is a new feature that allows the system to communicate with a third party service to privately retrieve information
about a phone number when an incoming call is coming in. This allows the system to automatically block known spam
callers and display identity information on the incoming call screen.

This repository provides a functional server backend to test the Live Caller ID Lookup feature.

> [!WARNING]
> While functional, this is just an example service and should not be run in production.

## Overview
Live caller ID Lookup Example provides:
* [PIRService](./Sources/PIRService/PIRService.docc/PIRService.md), an example service for Live Caller ID Lookup.
* [PrivacyPass](./Sources/PrivacyPass/PrivacyPass.docc/PrivacyPass.md), an implementation of the Privacy Pass publicly verifiable tokens.

## Developing Live Caller ID Lookup Example
Building Live Caller ID Lookup Example requires:
* 64-bit processor with little-endian memory representation
* macOS or Linux operating system
* [Swift](https://www.swift.org/) version 6.0 or later

Additionally, developing Live Caller ID Lookup Example requires:
* [Nick Lockwood swiftformat](https://github.com/nicklockwood/SwiftFormat)
* [pre-commit](https://pre-commit.com)
* [swiftlint](https://github.com/realm/SwiftLint)

### Building
You can build Live Caller ID Lookup Example either via XCode or via command line in a terminal.
#### XCode
To build Live Caller ID Lookup Example from XCode, simply open the root directory (i.e., the `live-caller-id-lookup-example` directory) of the repository in XCode.
See the [XCode documentation](https://developer.apple.com/documentation/xcode) for more details on developing with XCode.

#### Command line
To build Live Caller ID Lookup Example from command line, open the root directory (i.e., the `live-caller-id-lookup-example` directory) of the repository in a terminal, and run
```sh
swift build -c release
```
The build products will be in the `.build/release/` folder.

To build in debug mode, run
```sh
swift build
```
The build products will be in the `.build/debug/` folder.
> [!WARNING]
> Runtimes may be slow in debug mode.

### Testing
Run unit tests via
```sh
swift test -c release --parallel
```
To run tests in debug mode, run
```sh
swift test --parallel
```
> [!WARNING]
> Runtimes may be slow in debug mode.

### Contributing
If you would like to make a pull request to Live Caller ID Lookup Example, please run `pre-commit install`. Then each commit will run some basic formatting checks.

# Documentation
Live Caller ID Lookup Example uses DocC for documentation.
For more information, refer to [the DocC documentation](https://www.swift.org/documentation/docc) and the [Swift-DocC Plugin](https://apple.github.io/swift-docc-plugin/documentation/swiftdoccplugin).
## XCode
The documentation can be built from XCode via `Product -> Build Documentation`.
## Command line
The documentation can be built from command line by running
```sh
swift package generate-documentation
```
and previewed by running
```sh
swift package --disable-sandbox preview-documentation --target PIRService
```
