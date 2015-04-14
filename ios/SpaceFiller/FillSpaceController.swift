//
//  FillSpaceController.swift
//  SpaceFiller
//
//  Created by Jesus Lopez on 4/14/15.
//  Copyright (c) 2015 JLA. All rights reserved.
//

import UIKit

class FillSpaceController: UITableViewController {
  @IBOutlet weak var totalLabel: UILabel!
  @IBOutlet weak var availableLabel: UILabel!
  @IBOutlet weak var usedLabel: UILabel!
  @IBOutlet weak var lastErrorLabel: UILabel!
  @IBOutlet weak var blockSizeLabel: UILabel!
  @IBOutlet weak var blockSizeSlider: UISlider!
  var blockSize = 24 {
    didSet {
      blockSizeLabel?.text = formatNumber(1 << blockSize)
      blockSizeSlider.value = Float(blockSize) / 28.0
    }
  }
  var trackingBlockSize = false
  @IBAction func onSliderChanged(sender: UISlider) {
    if !trackingBlockSize {
      trackingBlockSize = true
      onSliderDone(sender)
      trackingBlockSize = false
    }
  }
  @IBAction func onSliderDone(sender: UISlider) {
    blockSize = Int(sender.value * 28)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    blockSize = blockSize + 0
    createFiller()
  }

  override func viewWillAppear(animated: Bool) {
    startRefresh()
  }

  override func viewDidDisappear(animated: Bool) {
    stopRefresh()
  }

  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
    if cell.selectionStyle != .None {
      cell.textLabel?.textColor = tableView.tintColor
    }
    return cell
  }

  let RefreshPeriod = 250
  var running = false
  func startRefresh() {
    running = true
    scheduleRefresh()
  }

  func stopRefresh() {
    running = false
  }

  func scheduleRefresh() {
    if running {
      let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(RefreshPeriod) * Int64(NSEC_PER_MSEC))
      dispatch_after(dispatchTime, dispatch_get_main_queue(), {
        self.refresh()
        self.updateFiller()
        self.scheduleRefresh()
      })
    }
  }

  func refresh() {
    updateStats()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

  var previous: String?
  func updateStats() {
    let total = formatNumber(getTotalSpace())
    let available = formatNumber(getAvailableSpace())
    let used = formatNumber(getFillerSize())
    totalLabel.text = total
    availableLabel.text = available
    usedLabel.text = used
    if previous != available {
      puts("\(total)   \(available)   \(used)")
      previous = available
    }
  }

  func formatNumber(n: Int) -> String {
    return NSString.localizedStringWithFormat("%lu", n) as String
  }

  func getTotalSpace() -> Int {
    return getFileSystemAttribute(NSFileSystemSize)
  }

  func getAvailableSpace() -> Int {
    return getFileSystemAttribute(NSFileSystemFreeSize)
  }

  func getFillerSize() -> Int {
    let mgr = NSFileManager.defaultManager()
    if let attributes = mgr.attributesOfItemAtPath(fillerPath, error: nil) {
      return attributes[NSFileSize] as! Int
    }
    return 0
  }

  lazy var documentsPath: String = {
    return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
    }()

  lazy var fillerPath: String = {
    return self.documentsPath.stringByAppendingPathComponent("filler.dat")
    }()

  func getFileSystemAttribute(attribute: String) -> Int {
    var error: NSError?;
    let mgr = NSFileManager.defaultManager()
    if let attributes = mgr.attributesOfFileSystemForPath(documentsPath, error: &error) {
      return attributes[attribute] as! Int
    }
    puts("Error getting attributes of path \(documentsPath): \(error)")
    return 0
  }

  func createFiller() {
    if !NSFileManager.defaultManager().fileExistsAtPath(fillerPath) {
      NSFileManager.defaultManager().createFileAtPath(fillerPath, contents: nil, attributes: nil);
    }
  }

  @IBOutlet weak var fillButton: UILabel!
  var filling = false {
    didSet {
      fillButton.text = filling ? "Stop" : "Use All"
    }
  }
  let UseMore = 100
  let UseLess = 101
  let UseAll = 102
  let LastError = 50
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let cell = tableView.cellForRowAtIndexPath(indexPath)!
    switch cell.tag {
    case UseMore: resizeFiller(1 << blockSize)
    case UseLess: resizeFiller(-(1 << blockSize))
    case UseAll: filling = !filling
    case LastError:
      if lastError != nil {
        let alert = UIAlertView(title: "Error", message: lastError, delegate: nil, cancelButtonTitle: "OK")
        alert.show()
      }
    default: break
    }
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }

  func resizeFiller(delta: Int) -> Bool {
    let newSize = max(getFillerSize() + delta, 0)
    var success = false
    if let handle = NSFileHandle(forUpdatingAtPath: fillerPath) {
      _try {
        handle.truncateFileAtOffset(UInt64(newSize))
        handle.closeFile()
        self.lastError = nil
        success = true
      }
      _catch {
        (exception: NSException!) in
        self.lastError = "\(exception.name): \(exception)"
      }
    } else {
      lastError = "ENOENT"
    }
    updateStats()
    return success
  }

  var lastError: String? {
    didSet {
      if lastError != nil {
        lastErrorLabel.text = lastError
        lastErrorLabel.textColor = UIColor.redColor()
        puts(lastError!)
      } else {
        lastErrorLabel.text = "N/A"
        lastErrorLabel.textColor = UIColor.grayColor()
      }
    }
  }

  func updateFiller() {
    if filling {
      if !resizeFiller(1 << blockSize) {
        if blockSize == 0 {
          blockSize = 22
          filling = false
        } else {
          --blockSize
        }
      }
    }
  }
}

