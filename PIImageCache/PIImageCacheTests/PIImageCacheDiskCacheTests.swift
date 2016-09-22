
// https://github.com/pixel-ink/PIImageCache

import UIKit
import XCTest

class PIImageDiskCacheTests: XCTestCase {

  let max = PIImageCache.Config().maxMemorySum
  
  func testDiskCache() {
    let cache = PIImageCache()
    var image: UIImage?, result: PIImageCache.Result
    var urls :[URL] = []
    for i in 0 ..< max * 2 {
      urls.append(URL(string: "http://place-hold.it/200x200/2ff&text=No.\(i)")!)
    }
    for i in 0 ..< max * 2 {
      (image, result) = cache.perform(urls[i])
      XCTAssert(result != .memoryHit, "Pass")
      XCTAssert(image!.size.width == 200 && image!.size.height == 200 , "Pass")
    }
    for i in 0 ..< max * 2 {
      (image, result) = cache.perform(urls[i])
      XCTAssert(result == .diskHit, "Pass")
      XCTAssert(image!.size.width == 200 && image!.size.height == 200 , "Pass")
    }
  }
  
  func testFileTimeStamp() {
    do {
    PIImageCache.shared.oldDiskCacheDelete()
    let config = PIImageCache.Config()
    let path = "\(config.cacheRootDirectory)\(config.cacheFolderName)/"
    let allFileName: [String]? = try FileManager.default.contentsOfDirectory(atPath: path)
    if let all = allFileName {
      for fileName in all {
        let attr = try FileManager.default.attributesOfItem(atPath: path + fileName)
          let diff = Date().timeIntervalSince( (attr[FileAttributeKey.modificationDate] as? Date) ?? Date(timeIntervalSince1970: 0) )
          XCTAssert( Double(diff) <= Double(config.diskCacheExpireMinutes * 60) , "Pass")
        
      }
    }
    } catch {}
  }
  
  func testPrefetch() {
    let cache = PIImageCache()
    var image: UIImage?, result: PIImageCache.Result
    var urls :[URL] = []
    for i in 0 ..< max * 2 {
      urls.append(URL(string: "http://place-hold.it/200x200/2ff&text=BackgroundNo.\(i)")!)
    }
    cache.prefetch(urls)
    for i in 0 ..< max * 2 {
      (image, result) = cache.perform(urls[i])
      XCTAssert(image!.size.width == 200 && image!.size.height == 200 , "Pass")
    }
    for i in 0 ..< max * 2 {
      (image, result) = cache.perform(urls[i])
      XCTAssert(result != .mishit, "Pass")
      XCTAssert(image!.size.width == 200 && image!.size.height == 200 , "Pass")
    }
  }
}
