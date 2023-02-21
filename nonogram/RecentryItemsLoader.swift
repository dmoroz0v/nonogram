//
//  RecentryItemsLoader.swift
//  nonogram
//
//  Created by Denis S. Morozov on 19.02.2023.
//

import Foundation
import UIKit

final class RecentryItemsLoader {
    private let storage: Storage

    init(storage: Storage) {
        self.storage = storage
    }

    func load(completion: @escaping (_ result: [ListItem]?) -> Void) {
        DispatchQueue.global().async {
            var result: [ListItem] = []
            for data in self.storage.recenty() {
                result.append(ListItem(url: data.url, thumbnailUrl: data.thumbnailUrl, title: data.title))
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
                completion(result)
            }
        }

    }
}
