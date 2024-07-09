# Data format for Live Caller ID Lookup

Understand the data format that the Live Caller ID Lookup expects.

## Overview

When a device receives an incoming call, the system reaches out to a third-party service to privately fetch data from
your server. It makes two Private Information Retrieval (PIR) requests:
* Blocking information request
* Identity information request

The system makes two PIR requests instead of single requests, because it needs the response to the blocking information
more quickly. The system delays ringing the phone while waiting for the blocking information. Identity information can
take longer to load; when it is received, the user interface will be updated.

### Blocking information

The blocking information response is a single byte with two defined values:

Value | Description
----- | -----------
0     | This value means don’t block the caller.
1     | This value means block the caller.

### Identity information
The identity information response is the information displayed on the device. This information is a serialized Protobuf
message of type `CallIdentity`. The Protobuf schema for `CallIdentity` follows:

```js
syntax = "proto3";

// Image format.
enum ImageFormat {
  // Unspecified format.
  IMAGE_FORMAT_UNSPECIFIED = 0;
  // High Efficiency Image File Format (HEIF / HEIC).
  IMAGE_FORMAT_HEIC = 1;
}

// Identity Category.
//
// The system might show identity information differently based on the category.
enum IdentityCategory {
  // Unspecified category.
  IDENTITY_CATEGORY_UNSPECIFIED = 0;
  // Person category.
  IDENTITY_CATEGORY_PERSON = 1;
  // Business category.
  IDENTITY_CATEGORY_BUSINESS = 2;
}

// Icon
message Icon {
  // Image format for the icon
  ImageFormat format = 1;
  // Encoded image in the specified format.
  bytes image = 2;
}

// Caller Identity
message CallIdentity {
  // Identity information.
  string name = 1;
  // Icon to be displayed with the identity.
  Icon icon = 2;
  // Cache expiry minutes.
  //
  // The system will reuse this response for this many minutes before requesting it again.
  uint32 cache_expiry_minutes = 3;
  // Identity category.
  IdentityCategory category = 4;
}
```
