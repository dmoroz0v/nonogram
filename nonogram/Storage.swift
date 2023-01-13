//
//  Storage.swift
//  nonogram
//
//  Created by Denis S. Morozov on 13.01.2023.
//

import Foundation

class Storage {
    struct Data: Codable {
        let field: Field
        let layers: [String: Field]
        let currentLayer: String?
    }

    func save(field: Field, layers: [String: Field], currentLayer: String?) {
        let data = Data(field: field, layers: layers, currentLayer: currentLayer)
        let d = try? JSONEncoder().encode(data)
        if let d = d {
            let str = String(decoding: d, as: UTF8.self)
            UserDefaults.standard.set(str, forKey: "Nonogram-Saved")
            UserDefaults.standard.synchronize()
        }
    }

    func load() -> Data? {
        let str = UserDefaults.standard.string(forKey: "Nonogram-Saved")
        if let str = str {
            if let d = str.data(using: .utf8) {
                return try? JSONDecoder().decode(Data.self, from: d)
            }
        }
        return nil
    }
}
