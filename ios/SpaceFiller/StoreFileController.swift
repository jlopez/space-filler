//
//  StoreFileController.swift
//  SpaceFiller
//
//  Created by Jesus Lopez on 4/14/15.
//  Copyright (c) 2015 JLA. All rights reserved.
//

import UIKit

class StoreFileController : UITableViewController {
  let BlockSize = 4096
  @IBOutlet weak var availableLabel: UILabel!
  @IBOutlet weak var storeSizeLabel: UILabel!
  @IBOutlet weak var backupSizeLabel: UILabel!
  @IBOutlet weak var lastErrorLabel: UILabel!
  @IBOutlet weak var desiredStoreSizeLabel: UILabel!
  @IBOutlet weak var desiredStoreSizeSlider: UISlider!

  // MARK: Overrides
  override func viewDidLoad() {
    desiredStoreSize = BlockSize
  }

  override func viewWillAppear(animated: Bool) {
    startRefresh()
  }

  override func viewDidDisappear(animated: Bool) {
    stopRefresh()
  }

  // MARK: Tableview
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
    if cell.selectionStyle != .None {
      cell.textLabel?.textColor = tableView.tintColor
    }
    return cell
  }

  let UpdateStore = 100
  let DeleteBackup = 101
  let DeleteStore = 102
  let LastError = 50
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    let cell = tableView.cellForRowAtIndexPath(indexPath)!
    switch cell.tag {
    case UpdateStore: updateStore()
    case DeleteBackup: deleteBackup()
    case DeleteStore: deleteStore()
    case LastError: showLastError()
    default: break
    }
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }

  // MARK: Refresh
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
        self.scheduleRefresh()
      })
    }
  }

  func refresh() {
    updateStats()
  }

  var previous: String?
  func updateStats() {
    let available = formatNumber(getAvailableSpace())
    let storeSize = formatNumber(getFileSize(storePath))
    let backupSize = formatNumber(getFileSize(backupPath))
    availableLabel.text = available
    storeSizeLabel.text = storeSize
    backupSizeLabel.text = backupSize
    if previous != available {
      puts("\(available)")
      previous = available
    }
  }

  func formatNumber(n: Int?) -> String {
    if n == nil {
      return "N/A"
    } else {
      return NSString.localizedStringWithFormat("%lu", n!) as String
    }
  }

  // MARK: Filesystem
  func getAvailableSpace() -> Int {
    return getFileSystemAttribute(NSFileSystemFreeSize)
  }

  func getFileSize(path: String) -> Int? {
    let mgr = NSFileManager.defaultManager()
    if let attributes = mgr.attributesOfItemAtPath(path, error: nil) {
      return attributes[NSFileSize] as? Int
    }
    return nil
  }

  lazy var documentsPath: String = {
    return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! String
    }()

  lazy var storePath: String = {
    return self.documentsPath.stringByAppendingPathComponent("store.dat")
    }()

  lazy var backupPath: String = {
    return self.documentsPath.stringByAppendingPathComponent("store.bak")
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

  func deleteFile(path: String) {
    let mgr = NSFileManager.defaultManager()
    var err: NSError?
    if mgr.fileExistsAtPath(path) && !mgr.removeItemAtPath(path, error: &err) {
      lastError = err
    }
    updateStats()
  }

  // Mark: Slider
  var desiredStoreSize = 0 {
    didSet {
      desiredStoreSizeLabel?.text = formatNumber(desiredStoreSize)
      desiredStoreSizeSlider.value = Float(desiredStoreSize - (BlockSize - 16)) / 32.0
    }
  }
  var trackingSlider = false
  @IBAction func onSliderChanged(sender: UISlider) {
    if !trackingSlider {
      trackingSlider = true
      onSliderDone(sender)
      trackingSlider = false
    }
  }
  @IBAction func onSliderDone(sender: UISlider) {
    desiredStoreSize = BlockSize - 16 + Int(sender.value * 32)
  }

  // MARK: Last Error
  var lastError: NSError? {
    didSet {
      if lastError != nil {
        var err = lastError!
        while let sub = err.userInfo?[NSUnderlyingErrorKey] as? NSError {
          err = sub
        }
        lastErrorLabel.text = err.localizedDescription
        lastErrorLabel.textColor = UIColor.redColor()
        puts(lastError!.description)
      } else {
        lastErrorLabel.text = "N/A"
        lastErrorLabel.textColor = UIColor.grayColor()
      }
    }
  }

  // MARK: Actions
  func updateStore() {
    lastError = nil
    let mgr = NSFileManager.defaultManager()
    deleteFile(backupPath)
    var err: NSError?
    if mgr.fileExistsAtPath(storePath) && !mgr.moveItemAtPath(storePath, toPath: backupPath, error: &err) {
      lastError = err
    }
    var data = NSMutableData(length: desiredStoreSize)!
    if !data.writeToFile(storePath, options: .allZeros, error: &err) {
      lastError = err
    }
    updateStats()
  }

  func deleteBackup() {
    deleteFile(backupPath)
  }

  func deleteStore() {
    deleteFile(storePath)
  }

  func showLastError() {
    if lastError != nil {
      let alert = UIAlertView(title: "Error", message: lastError?.description, delegate: nil, cancelButtonTitle: "OK")
      alert.show()
    }
  }
}
