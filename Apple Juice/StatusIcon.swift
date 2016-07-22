//
// StatusIcon.swift
// Apple Juice
// https://github.com/raphaelhanneken/apple-juice
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Raphael Hanneken
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Cocoa

///  Draws the status bar image.
internal struct StatusIcon {
  ///  Add a little offset to draw the capacity bar in the correct position.
  private let capacityOffsetX: CGFloat = 2.0
  ///  Caches the last drawn battery image.
  private var cache: BatteryImageCache?

  /// Returns the charged and plugged battery image.
  private var batteryPluggedAndCharged: NSImage? {
    return batteryImage(named: .charged)
  }

  /// Returns the charging battery image.
  private var batteryCharging: NSImage? {
    return batteryImage(named: .charging)
  }

  /// Returns the battery image for a ConnectionAlreadyOpen error.
  private var batteryConnectionAlreadyOpen: NSImage? {
    return batteryImage(named: .dead)
  }

  /// Returns the battery image for a ServiceNotFound error.
  private var batteryServiceNotFound: NSImage? {
    return batteryImage(named: .none)
  }


  // MARK: - Methods

  ///  Draws a battery image for the supplied BatteryStatusType.
  ///
  ///  - parameter status: The BatteryStatusType, which to draw the image for.
  ///  - returns:          The battery image for the provided battery status.
  mutating func drawBatteryImage(forStatus status: BatteryStatusType) -> NSImage? {
    // Check if an image is already cached.
    if let cache = self.cache {
      switch status {
      case .discharging(let percentage):
        if percentage != cache.percentage {
          NSLog("Cache discharging icon for %i %%", percentage)
          self.cache = BatteryImageCache(forStatus: status,
                                         withImage: batteryDischarging(currentPercentage: percentage),
                                         andPercentage: percentage)
        }
        fallthrough
      default:
        NSLog("- 01 - Returning cached battery image.")
        return cache.image
      }
    } else {
      // Cache a new battery image.
      switch status {
      case .charging:
        NSLog("Cache charging icon")
        self.cache = BatteryImageCache(forStatus: status, withImage: batteryCharging)
      case .pluggedAndCharged:
        NSLog("Cache pluggedAndCharged icon")
        self.cache = BatteryImageCache(forStatus: status, withImage: batteryPluggedAndCharged)
      case .discharging(let percentage):
        NSLog("Cache discharging icon for %i %%", percentage)
        self.cache = BatteryImageCache(forStatus: status,
                                       withImage: batteryDischarging(currentPercentage: percentage),
                                       andPercentage: percentage)
      }
    }
    // Return the battery image thats currently cached.
    NSLog("- 02 - Returning cached battery image.")
    return cache?.image
  }

  ///  Draw a battery image according to the provided BatteryError.
  ///
  ///  - parameter err: The BatteryError, which to draw the battery image for.
  ///  - returns:       The battery image for the supplied BatteryError.
  func drawBatteryImage(forError err: BatteryError?) -> NSImage? {
    // Unwrap the Error object.
    guard let error = err else {
      return nil
    }
    // Check the supplied error type.
    switch error {
    case .connectionAlreadyOpen:
      return batteryConnectionAlreadyOpen
    case .serviceNotFound:
      return batteryServiceNotFound
    }
  }


  // MARK: - Private Methods

  ///  Draws a battery icon based on the current percentage of the battery.
  ///
  ///  - parameter percentage: The current percentage of the battery.
  ///  - returns:              A battery image for the supplied percentage.
  private func dischargingBatteryImage(forPercentage percentage: Int) -> NSImage? {
    // Get the required images to draw the battery icon.
    guard let batteryEmpty     = batteryImage(named: .empty),
              capacityCapLeft  = batteryImage(named: .left),
              capacityCapRight = batteryImage(named: .right),
              capacityFill     = batteryImage(named: .middle) else {
        return nil
    }
    // Get the capacity bar's height.
    let capacityHeight = capacityFill.size.height
    // Calculate the offset to achieve that little gap between the capacity bar and the outline.
    let capacityOffsetY = batteryEmpty.size.height - (capacityHeight + capacityOffsetX)
    // Calculate the capacity bar's width.
    var capacityWidth = CGFloat(round(Double(percentage / 12))) * capacityFill.size.width
    // Don't draw the capacity bar smaller than two single battery
    // images, to prevent visual errors.
    if (2 * capacityFill.size.width) >= capacityWidth {
      capacityWidth = (2 * capacityFill.size.width) + 0.1
    }
    // Define the drawing rect in which to draw the capacity bar in.
    let drawingRect = NSRect(x: capacityOffsetX, y: capacityOffsetY,
                             width: capacityWidth, height: capacityHeight)

    // Draw the actual menu bar image.
    drawThreePartImage(frame: drawingRect, canvas: batteryEmpty, startCap: capacityCapLeft,
                       fill: capacityFill, endCap: capacityCapRight)

    return batteryEmpty
  }

  ///  Opens an image file for the supplied image name.
  ///
  ///  - parameter name: The name of the requested image.
  ///  - returns:        The requested image.
  private func batteryImage(named name: BatteryImage) -> NSImage? {
    // Define the path to apple's battery icons.
    let path = "/System/Library/PrivateFrameworks/BatteryUIKit.framework/Versions/A/Resources/"
    // Open the supplied file as NSImage.
    if let img = NSImage(contentsOfFile: "\(path)\(name.rawValue)") {
      return img
    } else {
      // The image with the supplied name was not found.
      print("Image named \(name.rawValue) not found!")
      return nil
    }
  }

  ///  Draws a three-part image onto a specified canvas image.
  ///
  ///  - parameter rect:  The rectangle in which to draw the images.
  ///  - parameter img:   The image on which to draw the three-part image.
  ///  - parameter start: The image located on the left end of the frame.
  ///  - parameter fill:  The image used to fill the gap between the start and the end images.
  ///  - parameter end:   The image located on the right end of the frame.
  private func drawThreePartImage(frame rect: NSRect, canvas img: NSImage,
                                         startCap start: NSImage, fill: NSImage, endCap end: NSImage) {
    img.lockFocus()
    NSDrawThreePartImage(rect, start, fill, end, false, .copy, 1, false)
    img.unlockFocus()
  }
}


///  Defines the filenames for Apple's battery images.
///
///  - left:     Left-hand side capacity bar cap.
///  - right:    Right-hand side capacity bar cap.
///  - middle:   Capacity bar filler filename.
///  - empty:    Empty battery filename.
///  - charged:  Charged and plugged battery filename.
///  - charging: Charging battery filename.
///  - dead:     IOService already open filename.
///  - none:     Battery IOService not found filename.
enum BatteryImage: String {
  case left     = "BatteryLevelCapB-L.pdf"
  case right    = "BatteryLevelCapB-R.pdf"
  case middle   = "BatteryLevelCapB-M.pdf"
  case empty    = "BatteryEmpty.pdf"
  case charged  = "BatteryChargedAndPlugged.pdf"
  case charging = "BatteryCharging.pdf"
  case dead     = "BatteryDeadCropped.pdf"
  case none     = "BatteryNone.pdf"
}
