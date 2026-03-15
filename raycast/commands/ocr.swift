#!/usr/bin/env swift

// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title OCR Clipboard
// @raycast.mode silent
// @raycast.icon 👁️
// @raycast.packageName Image Tools

// Documentation:
// @raycast.author shayegan
// @raycast.description OCR the image in the clipboard and copy the text

import AppKit
import Foundation
import Vision

func die(_ msg: String) -> Never {
  fputs("\(msg)\n", stderr)
  exit(1)
}

let pasteboard = NSPasteboard.general

guard let image = pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage,
      let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:])
else {
  die("No image found in clipboard")
}

let tempFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("raycast-ocr-\(UUID().uuidString).png")
try pngData.write(to: tempFile)
defer { try? FileManager.default.removeItem(at: tempFile) }

var recognizeTextRequest = RecognizeTextRequest()
recognizeTextRequest.automaticallyDetectsLanguage = true
recognizeTextRequest.usesLanguageCorrection = true
recognizeTextRequest.recognitionLevel = .accurate

guard let observations = try? await recognizeTextRequest.perform(on: tempFile) else {
  die("Couldn't recognize text")
}

var lines: [String] = []
for observation in observations {
  if let candidate = observation.topCandidates(1).first {
    lines.append(candidate.string)
  }
}

let result = lines.joined(separator: "\n")
if result.isEmpty {
  die("No text found in image")
}

pasteboard.clearContents()
pasteboard.setString(result, forType: .string)
print("Copied OCR text to clipboard")
