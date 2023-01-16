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

    private var saving = false
    private var pendingData: Data?

    func save(field: Field, layers: [String: Field], currentLayer: String?) {
        let data = Data(field: field, layers: layers, currentLayer: currentLayer)
        if saving {
            self.pendingData = data
            return
        }
        save(data)
    }

    private func save(_ data: Data) {
        saving = true
        DispatchQueue.global().async {

            let d = try? JSONEncoder().encode(data)
            if let d = d {
                let str = String(decoding: d, as: UTF8.self)
                UserDefaults.standard.set(str, forKey: "Nonogram-Saved")
                UserDefaults.standard.synchronize()
            }

            DispatchQueue.main.async {
                self.saving = false
                if let data = self.pendingData {
                    self.save(data)
                }
            }
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
