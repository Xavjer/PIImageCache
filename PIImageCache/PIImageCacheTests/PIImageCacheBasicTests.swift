
// https://github.com/pixel-ink/PIImageCache

import UIKit
import XCTest

class PIImageBasicCacheTests: XCTestCase {

  func testREADME() {
    
    //NSURL extension
    let url = URL(string: "http://place-hold.it/200x200")!
    var image = url.getImageWithCache()
    XCTAssert(image!.size.width == 200 && image!.size.height == 200 , "Pass")

    //UIImageView extension
    let imgView = UIImageView()
    imgView.imageOfURL(url) {
      isOK in
      XCTAssert(isOK , "Pass")
    }

    //for Background
    let cache = PIImageCache() // or PIImageCache.sherd
    image = cache.get(url)!
    XCTAssert(image!.size.width == 200 && image!.size.height == 200 , "Pass")
    let config = PIImageCache.Config()
    config.maxMemorySum = 5
    config.limitByteSize = 100 * 1024 // 100kB
    cache.setConfig(config)
    image = cache.get(url)!
    XCTAssert(image!.size.width == 200 && image!.size.height == 200 , "Pass")
  }
  
}
