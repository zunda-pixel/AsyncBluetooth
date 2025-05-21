// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "AsyncBluetooth",
  products: [
    .library(
      name: "AsyncBluetooth",
      targets: ["AsyncBluetooth"]
    ),
  ],
  targets: [
    .target(
      name: "AsyncBluetooth",
      swiftSettings: [
        .swiftLanguageMode(.v5)
      ]
    ),
  ]
)
