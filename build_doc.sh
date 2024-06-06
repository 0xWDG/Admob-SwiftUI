xcodebuild docbuild -scheme Admob-SwiftUI \
    -destination generic/platform=iOS \
    OTHER_DOCC_FLAGS="--transform-for-static-hosting --hosting-base-path . --output-path docs"