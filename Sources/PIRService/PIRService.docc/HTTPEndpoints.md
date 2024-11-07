# Setting up the HTTP endpoints for Live Caller ID Lookup

Learn about the required endpoints that the system expects from your service.

## Overview

Your client side app needs your
[serviceURL](https://developer.apple.com/documentation/sms_and_call_reporting/livecalleridlookupextensioncontext/4365180-serviceurl)
so the system can fetch information from your server. Communication between the system and server uses Protocol
Buffer (Protobuf) messages over HTTP. For the Protobuf schema please see [Homomorphic Encryption
Protobuf](https://github.com/apple/swift-homomorphic-encryption-protobuf).


The system expects three endpoints from the service:

1. The systems should be able to fetch configuration & get the status of evaluation keys stored on the server.
2. The system should be able to upload new evaluation key.
3. The system should be able to do Private Information Retrieval (PIR) queries.

### Get configuration and status
The system calls the configuration endpoint periodically to get information about the use case configuration and
evaluation key status.

Request        | Value              | Description
-------------- | ------------------ | -----------
Method         | POST               | HTTP method.
Path           | `/config`          | HTTP path.
Header         | `Authorization`    | The value will contain a private access token.
Header         | `User-Agent`       | Identifier for the user's OS type and version.
Header         | `User-Identifier`  | Pseudorandom identifier tied to a user.
Request Body   | `ConfigRequest`    | Serialized Protobuf message that list the use-cases that the system is interested in.
Response       | `ConfigResponse`   | Serialized Protobuf message. The `ConfigResponse` contains the `configs` and `key_info` response fields.
Response field | `configs`          | Map from use case names to the corresponding configuration.
Response field | `key_info`         | List of `KeyStatus` objects.

The system will cache the returned configurations. The `KeyStatus` objects are used to detect if the on-device key is in
sync with the evaluation key stored on the server.

### Upload evaluation key
When the system detects a new evaluation key, it uses this endpoint to upload it.

Request        | Value              | Description
-------------- | ------------------ | -----------
Method         | POST               | HTTP method.
Path           | `/key`             | HTTP path.
Header         | `Authorization`    | The value will contain a private access token.
Header         | `User-Agent`       | Identifier for the user's OS type and version.
Header         | `User-Identifier`  | Pseudorandom identifier tied to a user.
Body           | `EvaluationKeys`   | Serialized Protobuf message that contains evaluation key(s).

Your service should store the uploaded evaluation keys.

### PIR queries
This is the endpoint that answers to PIR requests. It uses the `User-Identifier` to look up the previously stored
evaluation key and uses it to evaluate the PIR request.

Request        | Value              | Description
-------------- | ------------------ | -----------
Method         | POST               | HTTP method.
Path           | `/queries`         | HTTP path.
Header         | `Authorization`    | The value will contain a private access token.
Header         | `User-Agent`       | Identifier for the user's OS type and version.
Header         | `User-Identifier`  | Pseudorandom identifier tied to a user.
Request Body   | `Requests`         | Serialized Protobuf message.
Response       | `Responses`        | Serialized Protobuf message.
