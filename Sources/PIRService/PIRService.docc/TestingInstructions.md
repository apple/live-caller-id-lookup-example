# Testing Live Caller ID Lookup

Learn how to run the example service.

## Overview

The primary objective of this example service is to provide a functional demonstration that can be utilized for testing
the feature. The general outline of the steps involved is as follows:

* Getting the tools.
* Preparing the dataset.
* Processing the dataset.
* Running the service.
* Writing the application extension.

## Getting the tools on your path

These testing steps assume that you have the following binaries available on your `$PATH`.
The binaries are:
 - `ConstructDatabase`
 - `PIRProcessDatabase`
 - `PIRService`

The way to add these to your path is by first making sure that the `~/.swiftpm/bin` directory is on your `$PATH`. To do
so, add the following line to your `~/.zshrc` or appropriate shell configuration file.
```sh
export PATH="$HOME/.swiftpm/bin:$PATH"
```
Make sure to reload it (`source ~/.zshrc`) or by restarting your terminal emulator. Then we are going to use the
`experimental-install` feature of Swift Package Manager.

### ConstructDatabase

Change directory to a checkout of this repository and run the following command.
```sh
swift package experimental-install -c release --product ConstructDatabase
```

### PIRProcessDatabase

This tool comes from the [main repository](https://github.com/apple/swift-homomorphic-encryption) of Swift Homomorphic
Encryption. Change directory to a checkout of the main repository and run the following command.

```sh
swift package experimental-install -c release --product PIRProcessDatabase
```

### PIRService

Change directory to a checkout of this repository and run the following command.
```sh
swift package experimental-install -c release --product PIRService
```

## Preparing the dataset

> Seealso: <doc:DataFormat>

Lets start by making a new directory:
```sh
mkdir ~/testing
cd ~/testing
```
Now you need to prepare a dataset that is going to be served. To make it a little simpler you are going to use the
`ContructDatabase` utility. Save the following as `input.txtpb`.

```json
identities {
  key: "+123"
  value {
    name: "Adam"
    cache_expiry_minutes: 8
    category: IDENTITY_CATEGORY_PERSON
  }
}
identities {
  key: "+1234"
  value {
    name: "Bob"
    cache_expiry_minutes: 7
    block: true
  }
}
identities {
  key: "+12345"
  value {
    name: "Grocery Store"
    cache_expiry_minutes: 18
    block: false
    category: IDENTITY_CATEGORY_BUSINESS
  }
}
```

> Note: You can also get the example input by observing the output of running `ConstuctDatabase` without arguments.

This file is a [text format representation](https://protobuf.dev/reference/protobuf/textformat-spec/) of protobuf data.
The schema for the message can be found at `Sources/ConstructDatabase/protobuf/InputIdentities.proto`. As you can see,
we have set up 3 identities.

### Adding icons
While `input.txtpb` contains almost all the fields that are needed, it is missing icons. Icons are somewhat hard to
represent in a textual format so `ConstructDatabase` provides a way to overcome that limitation. To add icons for the
identities create a new folder:

```sh
mkdir icons
```

And add icons as HEIC files to that folder. The filename should be: `$phonenumber.heic`. For example, after you have
added icons for "Adam" & "Grocery store" the directory listing should look like this:

```sh
$ ls icons
+123.heic
+12345.heic
```

> Warning: Images should be smaller than 64KB. We use 16-bit integers to encode the size of a value so the size of the
> `CallIdentity` protobuf message should not exceed 2^16-1 bytes.

> Tip: PIR runtime depends on the size of the images. For best performance, use small icons.

It is not necessary to provide icons for all identities. When `ConstuctDatabase` is parsing the input identities file,
it will search for the icon in the icons directory and attaches it if it is found.

## Constructing the two databases
Once we have prepared our input in the `input.txtpb` file and the `icons` folder. It is time to call:
```sh
ConstructDatabase --icon-directory icons input.txtpb block.binpb identity.binpb
```

This creates the `block.binpb` and `identity.binpb` files which are the blocking dataset and the identity dataset
expected for Live Caller ID Lookup. Both of these are in binary protobuf format, that is accepted by the
`PIRProcessDatabase` utility.

## Processing the datasets

Before setting up a server to host these two datasets we need to process them a bit, so the online PIR queries can be
done faster. For this we  will use the `PIRProcessDatabase` utility.

> Important: These example configurations are just for example. Please see
> [Keyword PIR Parameter
> Tuning](https://github.com/apple/swift-homomorphic-encryption/blob/578a38e1f7b2e4a4da26b93060ae31b89a4ea5e7/Sources/PrivateInformationRetrieval/PrivateInformationRetrieval.docc/ParameterTuning.md)
> to learn how to adjust the configuration for your dataset.

Write the following configuration into a file called `block-config.json`.
```json
{
  "inputDatabase": "block.binpb",
  "outputDatabase": "block-SHARD_ID.bin",
  "outputPirParameters": "block-SHARD_ID.params.txtpb",
  "rlweParameters": "n_4096_logq_27_28_28_logt_5",
  "sharding": {
    "entryCountPerShard": 1000
  },
  "trialsPerShard": 5
}
```
Now call the utility.

```sh
PIRProcessDatabase block-config.json
```

This instructs the `PIRProcessDatabase` utility to load the input from `block.binpb`, output the processed database into
a file called `block-0.bin`. See how the occurances of `SHARD_ID` get replaced in `block-SHARD_ID.bin` to become the
first (and only) shard in our case with name `block-0.binpb`. In addition to the processed database, the utility also
outputs a file called `block-0.params.txtpb`. This file holds the PIR parameters for the shard.

Now we do basically the same thing for the identity database: write the following into a file called
`identity-config.json`.
```json
{
  "inputDatabase": "identity.binpb",
  "outputDatabase": "identity-SHARD_ID.bin",
  "outputPirParameters": "identity-SHARD_ID.params.txtpb",
  "rlweParameters": "n_4096_logq_27_28_28_logt_5",
  "sharding" : {
    "entryCountPerShard" : 1000
  },
  "trialsPerShard": 5
}
```

And call `PIRProcessDatabase` to process the identity database.

```sh
PIRProcessDatabase identity-config.json
```

This will create the following files:
 - `identity-0.bin` - the processed database,
 - `identity-0.params.txtpb` - the PIR parameters for the identity database.

> Important: The blocking dataset is has very small entries and the identity dataset has larger entries. So it makes
> sense to use different parameters for them.

## Running the service

Copy the following to a file called `service-config.json`.

```json
{
  "issuerRequestUri": "http://lookup.example.net/issue",
  "users": [
    {
      "tier1": {}
    },
    [
      "AAAA"
    ],
    {
      "tier2": {}
    },
    [
      "BBBB",
      "CCCC"
    ]
  ],
  "usecases": [
    {
      "fileStem": "block",
      "shardCount": 1,
      "name": "net.example.lookup.block"
    },
    {
      "fileStem": "identity",
      "shardCount": 1,
      "name": "net.example.lookup.identity"
    }
  ]
}
```

This configuration file has 3 sections.

1. `issuerRequestUri` - This URL will be included in the Privacy Pass token issuer directory. It needs to end with
   `/issue` and point to the address of your service. In this example we assume that the service will be reachable at
   `http://lookup.example.net`.
> Note: This value can be omitted from the configuration. Setting this explicitly will not be required for devices using
> iOS 18.0 beta 4 or later.
2. `users` - This is a mapping from user tiers to User Tokens that are allowed for that tier. The User tokens are
   already base64 encoded as they appear in the HTTP `Authorization` header.
3. `usecases` - This is a list of usecases, where each usecase has the `fileStem`, `shardCount`, and `name`. When
   loading the usecase, `PIRService` does something like:
```swift
self.shards = try (0..<shardCount).map { shardIndex in
    let parameterPath = "\(fileStem)-\(shardIndex).params.txtpb"
    let databasePath = "\(fileStem)-\(shardIndex).bin"
    ...
}
```
The `name` will be used by the device to identify the dataset. In this example, we assume that the bundle identifier of
the on-device Live Caller ID Lookup Extension is `net.example.lookup`. Then the system will try to fetch the blocking
information from `net.example.lookup.block` and the identity information from `net.example.lookup.identity`.

After the configuration file is as it should be, it is time to run the example service:

```sh
PIRService --hostname 0.0.0.0 service-config.json
```

By default `PIRService` will start listening on the loopback interface, but you can add the `--hostname 0.0.0.0` part to
make it listen on all network interfaces. The default port is `8080`, but it can be changed by using the `--port`
option.

## Writing the application extension

> Important: Please see [Getting up-to-date calling and blocking information for your
> app](https://developer.apple.com/documentation/sms_and_call_reporting/getting_up-to-date_calling_and_blocking_information_for_your_app)
> for information how to create an Live Caller ID Lookup extension.

To configure your extension to talk to the example service you need to fill in
[the extension
context](https://developer.apple.com/documentation/sms_and_call_reporting/livecalleridlookupextensioncontext).

This example service provides both the service itself and the privacy pass token issuer. So we should set the
`serviceURL` and `tokenIssuerURL` both to the same value: `http://lookup.example.net:8080`. For the `userTierToken`,
please set it to one of the values that you added in the service configuration file in <doc:#Running-the-service>
section. For example `BBBB`.

```swift
var context: LiveCallerIDLookupExtensionContext { get {
    return LiveCallerIDLookupExtensionContext(
        // The URL for the server endpoint that the system uses to fetch incoming call information.
        serviceURL: URL(string: "http://lookup.example.net:8080")!,
        // The URL of the token issuer.
        tokenIssuerURL: URL(string: "http://lookup.example.net:8080")!,
        // The token to authenticate the app.
        userTierToken: Data(base64Encoded: "BBBB")!
    )
}}
```

### Running locally

When running things locally on your Mac, and your testing device is on the same network, then you can use mDNS to let
the device find your Mac. Let's assume that your Mac's hostname is `Tims-MacBook-Pro.local`.

> Note: You can find out your hostname by typing `hostname`.

Then we should use the following value for the URLs: `http://Tims-Macbook-Pro.local:8080`. Thanks to the mDNS protocol
your device should be able to resolve your hostname to the actual IP address of your Mac and make the connection.

> Tip: Do not forget to also update the `issuerRequestUri` field in the service configuration.
