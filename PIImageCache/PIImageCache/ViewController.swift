import UIKit

class ViewController: UIViewController {
  
  let cache = PIImageCache()
  
  let lormpixelCategory =
  [
    "animals",
    "cats",
    "city",
    "fashion"
  ]
  var count = 0
  @IBOutlet var imgView: UIImageView!
  
  @IBAction func btnPushed(_ sender: AnyObject) {
    count += 1
    if count >= lormpixelCategory.count {
      count = 0
    }
    let url = URL(string: "http://lorempixel.com/200/200/" + lormpixelCategory[count] )!
    imgView.imageOfURL(url)
  }
  
  override func didReceiveMemoryWarning() {
    cache.allMemoryCacheDelete()
  }
  
}
