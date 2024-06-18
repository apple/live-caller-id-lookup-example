# Contributing
Before contributing, please run `pre-commit install`.
Then each commit will run some basic formatting checks.

## Dependencies
* [pre-commit](https://pre-commit.com)
* [swiftformat](https://github.com/nicklockwood/SwiftFormat)
* [swiftlint](https://github.com/realm/SwiftLint)
* [Benchmark](https://swiftpackageindex.com/ordo-one/package-benchmark)
* [jemalloc](http://jemalloc.net) `brew install jemalloc`

# Benchmark
The benckmark can be trigged in either XCode by running the benchmark targets or by running `swift package -c release benchmark` (optionally with ` --target Your_Target`) under `swift-he/`
