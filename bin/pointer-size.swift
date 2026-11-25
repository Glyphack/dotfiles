#!/usr/bin/env swift

// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title Toggle Pointer Size
// @raycast.mode silent
// @raycast.packageName System

// Documentation:
// @raycast.author glyphack
// @raycast.description Switch the mouse pointer between small and big

// Usage: pointer-size.swift [small|big]
// Without an argument it switches to the other size.
//
// Changes the pointer size right away through the private CoreGraphics
// cursor scale API. The change lasts until logout, after that macOS goes back
// to the size set in System Settings > Accessibility > Display.

import Foundation

let smallScale: Float = 1.0
let bigScale: Float = 4.0

func die(_ msg: String) -> Never {
  fputs("\(msg)\n", stderr)
  exit(1)
}

struct CursorScale {
  typealias MainConnectionID = @convention(c) () -> Int32
  typealias GetCursorScale = @convention(c) (Int32, UnsafeMutablePointer<Float>) -> Int32
  typealias SetCursorScale = @convention(c) (Int32, Float) -> Int32

  let connection: Int32
  let getScale: GetCursorScale
  let setScale: SetCursorScale

  init() {
    let path = "/System/Library/Frameworks/ApplicationServices.framework/ApplicationServices"
    guard let handle = dlopen(path, RTLD_NOW) else {
      die("Could not load ApplicationServices")
    }
    func load<T>(_ name: String, as type: T.Type) -> T {
      guard let symbol = dlsym(handle, name) else {
        die("Missing symbol \(name)")
      }
      return unsafeBitCast(symbol, to: type)
    }
    connection = load("CGSMainConnectionID", as: MainConnectionID.self)()
    getScale = load("CGSGetCursorScale", as: GetCursorScale.self)
    setScale = load("CGSSetCursorScale", as: SetCursorScale.self)
  }

  func current() -> Float {
    var scale: Float = 0
    let err = getScale(connection, &scale)
    if err != 0 {
      die("Could not read pointer size (error \(err))")
    }
    return scale
  }

  func set(_ scale: Float) {
    let err = setScale(connection, scale)
    if err != 0 {
      die("Could not set pointer size (error \(err))")
    }
  }

  func toggled() -> Float {
    current() > smallScale ? smallScale : bigScale
  }
}

let cursor = CursorScale()
let scale: Float
switch CommandLine.arguments.dropFirst().first {
case nil:
  scale = cursor.toggled()
case "small":
  scale = smallScale
case "big":
  scale = bigScale
case let other?:
  die("Unknown size \(other), use small or big")
}
cursor.set(scale)
print(scale == smallScale ? "Pointer is small" : "Pointer is big")
