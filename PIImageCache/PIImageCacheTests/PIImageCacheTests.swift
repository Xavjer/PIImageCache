//
//  PIImageCacheTests.swift
//  PIImageCacheTests
//
//  Created by Yoshiki Fujiwara on 2015/06/11.
//  Copyright (c) 2015年 pixelink. All rights reserved.
//

import UIKit
import XCTest

class PIImageCacheTests: XCTestCase {

  func testDownload() {
    let cache = PIImageCache()
    let url = NSURL(string: "http://place-hold.it/200x200")!
    let image = cache.download(url)!
    XCTAssert(image.size.width == 200 && image.size.height == 200 , "Pass")
  }

  func testDownloadOrCache() {
    let cache = PIImageCache()
    let url = NSURL(string: "http://place-hold.it/200x200")!
    var image: UIImage?, isCache: Bool
    (image, isCache) = cache.downloadOrCache(url)
    XCTAssert(isCache == false, "Pass")
    XCTAssert(image!.size.width == 200 && image!.size.height == 200 , "Pass")
    (image, isCache) = cache.downloadOrCache(url)
    XCTAssert(isCache == true, "Pass")
    XCTAssert(image!.size.width == 200 && image!.size.height == 200 , "Pass")
  }

  func testCacheLimit() {
    let cache = PIImageCache()
    var image: UIImage?, isCache: Bool
    var urls :[NSURL] = []
    for i in 0 ..< 15 {
      urls.append(NSURL(string: "http://place-hold.it/200x200/2ff&text=No.\(i)")!)
    }
    for i in 0 ..< 10 {
      (image, isCache) = cache.downloadOrCache(urls[i])
      XCTAssert(isCache == false, "Pass")
      XCTAssert(image!.size.width == 200 && image!.size.height == 200 , "Pass")
    }
    for i in 0 ..< 10 {
      (image, isCache) = cache.downloadOrCache(urls[i])
      XCTAssert(isCache == true, "Pass")
      XCTAssert(image!.size.width == 200 && image!.size.height == 200 , "Pass")
    }
    for i in 10 ..< 15 {
      (image, isCache) = cache.downloadOrCache(urls[i])
      XCTAssert(isCache == false, "Pass")
      XCTAssert(image!.size.width == 200 && image!.size.height == 200 , "Pass")
    }
    for i in 0 ..< 10 {
      (image, isCache) = cache.downloadOrCache(urls[i])
      XCTAssert(isCache == false, "Pass")
      XCTAssert(image!.size.width == 200 && image!.size.height == 200 , "Pass")
    }
    for i in 0 ..< 10 {
      (image, isCache) = cache.downloadOrCache(urls[i])
      XCTAssert(isCache == true, "Pass")
      XCTAssert(image!.size.width == 200 && image!.size.height == 200 , "Pass")
    }
    for i in 10 ..< 15 {
      (image, isCache) = cache.downloadOrCache(urls[i])
      XCTAssert(isCache == false, "Pass")
      XCTAssert(image!.size.width == 200 && image!.size.height == 200 , "Pass")
    }
  }
  
  func testGet() {
    let cache = PIImageCache()
    let url = NSURL(string: "http://place-hold.it/200x200")!
    let image = cache.get(url)!
    XCTAssert(image.size.width == 200 && image.size.height == 200 , "Pass")
  }
  
  func testAsync() {
    let cache = PIImageCache()
    let url = NSURL(string: "http://place-hold.it/200x200")!
    cache.get(url) {
      image in
      XCTAssert(image!.size.width == 200 && image!.size.height == 200 , "Pass")
    }
  }
  
  func testExtension() {
    let url = NSURL(string: "http://place-hold.it/200x200")!
    let cache = PIImageCache()
    let image = url.getImageWithCache(cache)!
    XCTAssert(image.size.width == 200 && image.size.height == 200 , "Pass")
  }
  
}
