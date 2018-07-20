# RxEpub

[![CI Status](http://img.shields.io/travis/izhoubin/RxEpub.svg?style=flat)](https://travis-ci.org/izhoubin/RxEpub)
[![Version](https://img.shields.io/cocoapods/v/RxEpub.svg?style=flat)](http://cocoapods.org/pods/RxEpub)
[![License](https://img.shields.io/cocoapods/l/RxEpub.svg?style=flat)](http://cocoapods.org/pods/RxEpub)
[![Platform](https://img.shields.io/cocoapods/p/RxEpub.svg?style=flat)](http://cocoapods.org/pods/RxEpub)

## Example

You can load epub from local or remote files whether it's unziped or not.

//1. Load local epub</br>
//let url = Bundle.main.url(forResource: "330151", withExtension: "epub")

//2. Load local epub (unziped)</br>
//let url = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("Epubs").appendingPathComponent("330151")

//3. Load remote epub</br>
//let url = URL(string: "http://localhost/330151.epub")

//4. Load remote epub （unziped）</br>
//let url =  URL(string:"http://localhost/330151")

let vc = RxEpubPageController(url:url)</br>
navigationController?.pushViewController(vc, animated: true)


To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

- iOS 9.0+
- Xcode 9+

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
