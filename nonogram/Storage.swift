//
//  Storage.swift
//  nonogram
//
//  Created by Denis S. Morozov on 13.01.2023.
//

import Foundation

class Storage {
    struct Data: Codable {
        let url: URL
        let thumbnail: URL
        let title: String
        let field: Field
        let layers: [String: Field]
        let selectedLayerColor: Field.Color?
        let solution: [[Int]]
        let colors: [Field.Color]
    }

    private var saving = false
    private var pendingData: Data?

    func save(key: String,
              url: URL,
              thumbnail thumbnailUrl: URL,
              title: String,
              field: Field,
              layers: [String: Field],
              selectedLayerColor: Field.Color?,
              solution: [[Int]],
              colors: [Field.Color]
    ) {
        let data = Data(
            url: url,
            thumbnail: thumbnailUrl,
            title: title,
            field: field,
            layers: layers,
            selectedLayerColor: selectedLayerColor,
            solution: solution,
            colors: colors
        )
        if saving {
            self.pendingData = data
            return
        }
        save(data, key: key)
    }

    private func save(_ data: Data, key: String) {
        saving = true
        DispatchQueue.global().async {

            let d = try? JSONEncoder().encode(data)
            if let d = d {
                let str = String(decoding: d, as: UTF8.self)
                UserDefaults.standard.set(str, forKey: "Nonogram-Saved" + key)
                UserDefaults.standard.set(str, forKey: "Nonogram-Saved-Last")
                UserDefaults.standard.synchronize()
            }

            DispatchQueue.main.async {
                self.saving = false
                if let data = self.pendingData {
                    self.save(data, key: key)
                }
            }
        }
    }

    func loadLast() -> Data? {
        return load(key: "-Last")
    }

    func load(key: String) -> Data? {
        let str = UserDefaults.standard.string(forKey: "Nonogram-Saved" + key)
        if let str = str {
            if let d = str.data(using: .utf8) {
                return try? JSONDecoder().decode(Data.self, from: d)
            }
        }
        return nil
    }
}
