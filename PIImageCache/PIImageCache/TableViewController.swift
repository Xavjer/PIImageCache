import UIKit


class TableViewCell : UITableViewCell {
  @IBOutlet weak var icon: UIImageView!
  @IBOutlet weak var body: UILabel!
  var id:Int!
}

class TableViewController : UITableViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    var urls: [URL] = []
    for category in lormpixelCategory {
      urls.append( URL(string: "http://lorempixel.com/200/200/" + category)! )
    }
    PIImageCache.shared.prefetch(urls)
  }
  
  let lormpixelCategory =
  [ "abstract", "animals", "business", "cats", "city", "food", "nightlife", "fashion", "people", "nature", "sports", "technics", "transport", "abstract", "animals", "business", "cats", "city", "food", "nightlife", "fashion", "people", "nature", "sports", "technics", "transport" ]
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return lormpixelCategory.count
  }
  
  override func tableView(_ tableView: UITableView,
    cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell: TableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TableViewCell
      let i = (indexPath as NSIndexPath).row
      cell.id = i
      let url = URL(string: "http://lorempixel.com/200/200/" + lormpixelCategory[i] )!
      PIImageCache.shared.getWithId(url, id: i) { (id, image) in
        if id == cell.id {
          cell.icon.image = image
        }
      }
      cell.body.text = lormpixelCategory[i]
      return cell
  }
  
}
