
# Protobuf files

The files in `../generated` are generated from these protobuf files using the following command at the root of the repository.


```sh
find Sources/ConstructDatabase/protobuf -name "*.proto" -exec protoc -I Sources/ConstructDatabase/protobuf --swift_out Sources/ConstructDatabase/generated {} \;
```
