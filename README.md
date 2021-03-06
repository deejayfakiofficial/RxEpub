# RxEpub

[![CI Status](http://img.shields.io/travis/izhoubin/RxEpub.svg?style=flat)](https://travis-ci.org/izhoubin/RxEpub)
[![Version](https://img.shields.io/cocoapods/v/RxEpub.svg?style=flat)](http://cocoapods.org/pods/RxEpub)
[![License](https://img.shields.io/cocoapods/l/RxEpub.svg?style=flat)](http://cocoapods.org/pods/RxEpub)
[![Platform](https://img.shields.io/cocoapods/p/RxEpub.svg?style=flat)](http://cocoapods.org/pods/RxEpub)
[![Swift](https://img.shields.io/badge/Swift-5.0-brightgreen.svg)](http://cocoapods.org/pods/RxEpub)

## Example

### You can load epub from local or remote files whether it's unziped or not.

#### 1. Load local epub
```
let url = Bundle.main.url(forResource: "330151", withExtension: "epub")
```
#### 2. Load local epub (unziped)
```
let url = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("Epubs").appendingPathComponent("330151")
```
#### 3. Load remote epub
```
let url = URL(string: "http://d18.ixdzs.com/113/113933/113933.epub")
```
#### 4. Load remote epub （unziped）
```
let url =  URL(string:"http://localhost/330151")
```
### 5 . Parse epub
```
RxEpubParser(url: url).parse().subscribe(onNext: {[weak self] (book) in
    print(book.title)
    print(book.author)
}
```
####  Open reader
```
let vc = RxEpubPageController(url:url)
navigationController?.pushViewController(vc, animated: true)
```

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

- iOS 10.0+
- Xcode 10+

## Installation

RxEpub is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'RxEpub'
```
## Author

izhoubin, 121160492@qq.com

## License

RxEpub is available under the MIT license. See the [LICENSE](/LICENSE) file for more info.
