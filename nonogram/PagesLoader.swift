//
//  PagesLoader.swift
//  nonogram
//
//  Created by Denis S. Morozov on 19.02.2023.
//

import Foundation
import UIKit
import SwiftSoup

final class PagesLoader {

    struct Result {
        var items: [ListItem]
        var pagesCount: Int
    }

    struct Filter: Equatable {
        var name: String
        var url: URL
    }

    let filters: [Filter] = [
        Filter(name: "Все", url: URL(string: "https://www.nonograms.ru/nonograms2/p")!),
        Filter(name: "Крошечные", url: URL(string: "https://www.nonograms.ru/nonograms2/size/xsmall/p")!),
        Filter(name: "Маленькие", url: URL(string: "https://www.nonograms.ru/nonograms2/size/small/p")!),
        Filter(name: "Средние", url: URL(string: "https://www.nonograms.ru/nonograms2/size/medium/p")!),
        Filter(name: "Большие", url: URL(string: "https://www.nonograms.ru/nonograms2/size/large/p")!),
        Filter(name: "Огромные", url: URL(string: "https://www.nonograms.ru/nonograms2/size/xlarge/p")!),
        Filter(name: "Гигантские", url: URL(string: "https://www.nonograms.ru/nonograms2/size/xxlarge/p")!),
    ]

    private var isLoading = false

    func loadPage(_ page: Int, filter: Filter, completaion: @escaping (_ items: Result?) -> Void) {
        if isLoading {
            return
        }
        isLoading = true
        DispatchQueue.global().async {
            do {
                let data = try Data(contentsOf: filter.url.appendingPathComponent("\(page)"))

                if let s = String(data: data, encoding: .utf8) {
                    let doc: Document = try SwiftSoup.parse(s)

                    var result: [ListItem] = []
                    for tr in try doc.select("table.nonogram_list").tryFirst().select("tr") {
                        let nonogramImg = try tr.select("td.nonogram_img")
                        if let nonogramImg = nonogramImg.first() {
                            let urlString = try nonogramImg.select("a").tryFirst().attr("href")
                            var iconUrlString = try nonogramImg.select("img").tryFirst().attr("src")
                            iconUrlString = iconUrlString.replacingOccurrences(of: "_0.png", with: "_1.png")
                            let name = try nonogramImg.select("img").tryFirst().attr("title")
                            if let url = URL(string: urlString), let thumbnailUrl = URL(string: iconUrlString) {
                                result.append(ListItem(url: url, thumbnailUrl: thumbnailUrl, title: name))
                            }
                        }
                    }

                    let pages = try doc.select("div.pager").tryFirst().select("div").tryFirst().select("a")

                    var pagesCount: Int?
                    for a in pages.reversed() {
                        if let count = Int(try a.text()) {
                            pagesCount = count
                            break
                        }
                    }

                    guard let pagesCount else {
                        DispatchQueue.main.async {
                            self.isLoading = false
                            completaion(nil)
                        }
                        return
                    }

                    let group = DispatchGroup()

                    result.enumerated().forEach { index, item in
                        group.enter()
                        DispatchQueue.global().async {
                            if let data = try? Data(contentsOf: item.thumbnailUrl) {
                                if let image = UIImage(data: data) {
                                    result[index].image = image
                                }
                            }
                            group.leave()
                        }
                    }

                    group.wait()

                    DispatchQueue.main.async {
                        self.isLoading = false
                        completaion(Result(items: result, pagesCount: pagesCount))
                    }

                } else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        completaion(nil)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                    completaion(nil)
                }
            }
        }
    }
}

private extension Elements {
    func tryFirst() throws -> Element {
        if let first = first() {
            return first
        }
        throw NSError()
    }
}
