# How to onboard Live Caller ID Lookup extension with Apple Private relay

Understand the requirements for running a Live Caller ID Lookup service.

## Overview

To hide client’s IP address all network request made by the system to the Live Caller ID Lookup server will go over
[Oblivious HTTP](https://www.rfc-editor.org/rfc/rfc9458). Apple will provide the oblivious relay and therefore there is
a required onboarding step to make sure that Apple’s oblivious HTTP relay has been configured to forward requests to
your chosen oblivious HTTP gateway.

![Oblivious HTTP flow diagram](oblivious-http.png)

## How to test without private relay

The system does not use private relay, when the application is installed directly from Xcode. This allows the
application & the service deployment to be tested before filling out the onboarding form and setting up private relay.


## Requirements

Before you can fill out the form, there are a few requirements you have to satisfy to ensure smooth operations.


1. You must know the bundle identifier of your Live Caller ID Lookup extension.
2. You need to provide expected request and response size and per continent traffic estimates that include:
    * peak requests per second
    * total requests per day
3. You have added a test identity (+14085551212 with name “Johnny Appleseed”) to your dataset.
4. You have set up an Oblivious HTTP gateway.
5. You must provide your Oblivious HTTP Gateway configuration resource.
6. You must provide your Oblivious HTTP Gateway resource -- a URL used to make oblivious HTTP requests to your service.
7. You must provide your Privacy Pass Token Issuer URL.
8. You must provide your service URL.
9. You must provide an HTTP Bearer token, that allows us to validate that your deployment is set up correctly and we can
   successfully fetch the test identity.
10. You must add a DNS TXT record to your service URL to prove your ownership, control, and intent to serve Live Caller
    ID Lookups. More specifically you need to add the following record:
    `apple-live-caller-id-lookup=<bundle_identifier>` where `<bundle_identifier>` is replaced with your extension's
    bundle identifier. For example, if your Live Caller ID Lookup extension's bundle identifier is `net.example.lookup`
    the DNS TXT record should be: `apple-live-caller-id-lookup=net.example.lookup`.
11. You must ensure that your deployment (including Oblivious HTTP gateway & PIR service) is running so that we can
    perform the validation test.

## Onboarding form

The onboarding form should be filled out when you have a working service, but before you start distributing your
application with the Live Caller ID Lookup extension.

> Important: [Link to the onboarding form.](https://developer.apple.com/contact/request/live-caller-id-lookup/)
