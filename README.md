# Live Caller ID Lookup Example

[Live Caller ID
Lookup](https://developer.apple.com/documentation/sms_and_call_reporting/getting_up-to-date_calling_and_blocking_information_for_your_app)
is a new feature that allows the system to communicate with a third party service to privately retrieve information
about a phone number for an incoming call. This allows the system to automatically block known spam
callers and display identity information on the incoming call screen.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/apple/live-caller-id-lookup-example/raw/main/Sources/PIRService/PIRService.docc/Resources/overview~dark@2x.png">
  <img alt="Overview of the Live Caller ID Lookup" src="https://github.com/apple/live-caller-id-lookup-example/raw/main/Sources/PIRService/PIRService.docc/Resources/overview@2x.png">
</picture>

This repository provides a functional server backend to test the Live Caller ID Lookup feature.

> [!WARNING]
> While functional, this is just an example service and should not be run in production.

## Overview
Live caller ID Lookup Example provides:
* [PIRService](https://swiftpackageindex.com/apple/live-caller-id-lookup-example/main/documentation/pirservice), an example service for Live Caller ID Lookup.
* [PrivacyPass](https://swiftpackageindex.com/apple/live-caller-id-lookup-example/main/documentation/privacypass), an implementation of the Privacy Pass publicly verifiable tokens.

The documentation lives at [Swift Package Index](https://swiftpackageindex.com/apple/live-caller-id-lookup-example).

## Developing Live Caller ID Lookup Example
Building Live Caller ID Lookup Example requires:
* 64-bit processor with little-endian memory representation
* macOS or Linux operating system
* [Swift](https://www.swift.org/) version 6.0 or later

Additionally, developing Live Caller ID Lookup Example requires:
* [Nick Lockwood SwiftFormat](https://github.com/nicklockwood/SwiftFormat)
* [pre-commit](https://pre-commit.com)
* [SwiftLint](https://github.com/realm/SwiftLint)

### Building
You can build Live Caller ID Lookup Example either via Xcode or via command line in a terminal.
#### Xcode
To build Live Caller ID Lookup Example from Xcode, simply open the root directory (i.e., the `live-caller-id-lookup-example` directory) of the repository in Xcode.
See the [Xcode documentation](https://developer.apple.com/documentation/xcode) for more details on developing with Xcode.

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

### Documentation
Live Caller ID Lookup Example uses DocC for documentation.
For more information, refer to [the DocC documentation](https://www.swift.org/documentation/docc) and the [Swift-DocC Plugin](https://swiftlang.github.io/swift-docc-plugin/documentation/swiftdoccplugin).
#### Xcode
The documentation can be built from Xcode via `Product -> Build Documentation`.
#### Command line
The documentation can be built from command line by running
```sh
swift package generate-documentation
```
and previewed by running
```sh
swift package --disable-sandbox preview-documentation --target PIRService
```
