
// https://github.com/pixel-ink/PIImageCache

import UIKit

open class PIImageCache {
    
    //initialize
    
    fileprivate func myInit() {
        folderCreate()
        prefetchQueueInit()
    }
    
    public init() {
        myInit()
    }
    
    public init(config: Config) {
        let _ = memorySemaphore.wait(timeout: DispatchTime.distantFuture)
        self.config = config
        memorySemaphore.signal()
        myInit()
    }
    
    open class var shared: PIImageCache {
        struct Static {
            static let instance: PIImageCache = PIImageCache()
        }
        Static.instance.myInit()
        return Static.instance
    }
    
    //public config method
    
    open class Config {
        public init() {}
        open var maxMemorySum           : Int    = 10 // 10 images
        open var limitByteSize          : Int    = 3 * 1024 * 1024 //3MB
        open var usingDiskCache         : Bool   = true
        open var diskCacheExpireMinutes : Int    = 24 * 60 // 1 day
        open var prefetchOprationCount  : Int    = 5
        open var cacheRootDirectory     : String = NSTemporaryDirectory()
        open var cacheFolderName        : String = "PIImageCache"
    }
    
    open func setConfig(_ config :Config) {
        let _ = memorySemaphore.wait(timeout: DispatchTime.distantFuture)
        self.config = config
        myInit()
        memorySemaphore.signal()
    }
    
    //public download method
    
    open func get(_ url: URL) -> UIImage? {
        return perform(url).0
    }
    
    open func get(_ url: URL, then: @escaping (_ image:UIImage?) -> Void) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            [weak self] in
            let image = self?.get(url)
            DispatchQueue.main.async {
                then(image)
            }
        }
    }
    
    open func getWithId(_ url: URL, id: Int, then: @escaping (_ id: Int, _ image: UIImage?) -> Void) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
            [weak self] in
            let image = self?.get(url)
            DispatchQueue.main.async {
                then(id, image)
            }
        }
    }
    
    open func prefetch(_ urls: [URL]) {
        for url in urls {
            prefetch(url)
        }
    }
    
    open func prefetch(_ url: URL) {
        let op = Operation()
        op.completionBlock = {
            [weak self] in
            self?.downloadToDisk(url)
        }
        prefetchQueue.addOperation(op)
    }
    
    //public delete method
    
    open func allMemoryCacheDelete() {
        let _ = memorySemaphore.wait(timeout: DispatchTime.distantFuture)
        memoryCache.removeAll(keepingCapacity: false)
        memorySemaphore.signal()
    }
    
    open func allDiskCacheDelete() {
        do {
            let path = PIImageCache.folderPath(config)
            let _ = diskSemaphore.wait(timeout: DispatchTime.distantFuture)
            let allFileName: [String]? = try fileManager.contentsOfDirectory(atPath: path)
            if let all = allFileName {
                for fileName in all {
                    try fileManager.removeItem(atPath: path + fileName)
                }
            }
            folderCreate()
            diskSemaphore.signal()
        } catch {}
    }
    
    open func oldDiskCacheDelete() {
        do {
            let path = PIImageCache.folderPath(config)
            let _ = diskSemaphore.wait(timeout: DispatchTime.distantFuture)
            let allFileName: [String]? = try fileManager.contentsOfDirectory(atPath: path)
            if let all = allFileName {
                for fileName in all {
                    let attr = try fileManager.attributesOfItem(atPath: path + fileName)
                    let diff = Date().timeIntervalSince( (attr[FileAttributeKey.modificationDate] as? Date) ?? Date() )
                    if Double(diff) > Double(config.diskCacheExpireMinutes * 60) {
                        try fileManager.removeItem(atPath: path + fileName)
                    }
                    
                }
            }
            folderCreate()
            diskSemaphore.signal()
        } catch {}
    }
    
    //member
    
    fileprivate var config: Config = Config()
    fileprivate var memoryCache : [memoryCacheImage] = []
    fileprivate var memorySemaphore = DispatchSemaphore(value: 1)
    fileprivate var diskSemaphore = DispatchSemaphore(value: 1)
    fileprivate let fileManager = FileManager.default
    fileprivate let prefetchQueue = OperationQueue()
    
    fileprivate struct memoryCacheImage {
        let image     :UIImage
        var timeStamp :Double
        let url       :URL
    }
    
    // memory cache
    
    fileprivate func memoryCacheRead(_ url: URL) -> UIImage? {
        for i in 0 ..< memoryCache.count {
            if url == memoryCache[i].url {
                memoryCache[i].timeStamp = now
                return memoryCache[i].image
            }
        }
        return nil
    }
    
    fileprivate func memoryCacheWrite(_ url:URL,image:UIImage) {
        switch memoryCache.count {
        case 0 ... config.maxMemorySum:
            memoryCache.append(memoryCacheImage(image: image, timeStamp: now, url: url))
        case config.maxMemorySum + 1://+1 because 0 origin
            var old = (0,now)
            for i in 0 ..< memoryCache.count {
                if old.1 < memoryCache[i].timeStamp {
                    old = (i,memoryCache[i].timeStamp)
                }
            }
            memoryCache.remove(at: old.0)
            memoryCache.append(memoryCacheImage(image: image, timeStamp:now, url: url))
        default:
            for _ in 0 ... 1 {
                var old = (0,now)
                for i in 0 ..< memoryCache.count {
                    if old.1 < memoryCache[i].timeStamp {
                        old = (i,memoryCache[i].timeStamp)
                    }
                }
                memoryCache.remove(at: old.0)
            }
            memoryCache.append(memoryCacheImage(image: image, timeStamp:now, url: url))
        }
    }
    
    //disk cache
    
    
    fileprivate func diskCacheRead(_ url: URL) -> UIImage? {
        if let path = PIImageCache.filePath(url, config: config) {
            return UIImage(contentsOfFile: path)
        }
        return nil
    }
    
    fileprivate func diskCacheWrite(_ url:URL,image:UIImage) {
            if let path = PIImageCache.filePath(url, config: config) {
                _ = NSData(data: UIImagePNGRepresentation(image)!).write(toFile: path, atomically: true)
            }
    }
    
    //private download
    
    internal enum Result {
        case mishit, memoryHit, diskHit
    }
    
    internal func download(_ url: URL) -> (UIImage, byteSize: Int)? {
        do {
            let maybeImageData = try NSData(contentsOf: url, options: .uncachedRead)
            let imageData = maybeImageData
            if let image = UIImage(data: imageData as Data) {
                let bytes = imageData.length
                return (image, bytes)
            }
            
        } catch {}
        return nil
        
    }
    
    internal func perform(_ url: URL) -> (UIImage?, Result) {
        
        //memory read
        let _ = memorySemaphore.wait(timeout: DispatchTime.distantFuture)
        let maybeMemoryCache = memoryCacheRead(url)
        memorySemaphore.signal()
        if let cache = maybeMemoryCache {
            return (cache, .memoryHit)
        }
        
        //disk read
        if config.usingDiskCache {
            let _ = diskSemaphore.wait(timeout: DispatchTime.distantFuture)
            let maybeDiskCache = diskCacheRead(url)
            diskSemaphore.signal()
            if let cache = maybeDiskCache {
                let _ = memorySemaphore.wait(timeout: DispatchTime.distantFuture)
                memoryCacheWrite(url, image: cache)
                memorySemaphore.signal()
                return (cache, .diskHit)
            }
        }
        
        //download
        let maybeImage = download(url)
        if let (image, byteSize) = maybeImage {
            if byteSize < config.limitByteSize {
                //write memory
                let _ = memorySemaphore.wait(timeout: DispatchTime.distantFuture)
                memoryCacheWrite(url, image: image)
                memorySemaphore.signal()
                //write disk
                if config.usingDiskCache {
                    DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async {
                        [weak self] in
                        if let scope = self {
                            let _ = scope.diskSemaphore.wait(timeout: DispatchTime.distantFuture)
                            scope.diskCacheWrite(url, image: image)
                            scope.diskSemaphore.signal()
                        }
                    }
                }
            }
        }
        return (maybeImage?.0, .mishit)
    }
    
    fileprivate func downloadToDisk(_ url: URL) {
        let path = PIImageCache.filePath(url, config: config)
        if path == nil { return }
        if fileManager.fileExists(atPath: path!) { return }
        let maybeImage = download(url)
        if let (image, byteSize) = maybeImage {
            if byteSize < config.limitByteSize {
                let _ = diskSemaphore.wait(timeout: DispatchTime.distantFuture)
                diskCacheWrite(url, image: image)
                diskSemaphore.signal()
            }
        }
    }
    
    //util
    
    fileprivate var now: Double {
        get {
            return Date().timeIntervalSince1970
        }
    }
    
    fileprivate func folderCreate() {
        do {
            let path = "\(config.cacheRootDirectory)\(config.cacheFolderName)/"
            try fileManager.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
        } catch {}
    }
    
    fileprivate class func filePath(_ url: URL, config:Config) -> String? {
        let urlstr = String(url.absoluteString.characters.reversed())
        var code = ""
        var maxLength: Int = 40
        for char in urlstr.utf8 {
            code = code + "u\(char)"
            maxLength -= 1
            if maxLength == 0 {
                break
            }
        }
        return "\(config.cacheRootDirectory)\(config.cacheFolderName)/\(code)"
        
        //return nil
    }
    
    fileprivate class func folderPath(_ config: Config) -> String {
        return "\(config.cacheRootDirectory)\(config.cacheFolderName)/"
    }
    
    fileprivate func prefetchQueueInit(){
        prefetchQueue.maxConcurrentOperationCount = config.prefetchOprationCount
        prefetchQueue.qualityOfService = QualityOfService.background
    }
    
}
