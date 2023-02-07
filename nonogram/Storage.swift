//
//  Storage.swift
//  nonogram
//
//  Created by Denis S. Morozov on 13.01.2023.
//

import Foundation
import SQLite

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

    private lazy var dbPath: String = {
        func getDocumentsDirectory() -> URL {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let documentsDirectory = paths[0]
            return documentsDirectory
        }

        return getDocumentsDirectory().appendingPathComponent("db.sqlite3").path
    }()

    private func initDBIfNeeded() {
        if !FileManager.default.fileExists(atPath: dbPath) {
            initDB()
        }
    }

    private func initDB() {
        FileManager.default.createFile(atPath: dbPath, contents: .init())
        do {
            let db = try Connection(dbPath)
            let saves = Table("saves")
            let id = Expression<String>("id")
            let json = Expression<String?>("json")

            try db.run(saves.create { t in
                t.column(id, primaryKey: true)
                t.column(json)
            })
        } catch {
        }
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

            do {
                self.initDBIfNeeded()

                let jsonString = String(decoding: try JSONEncoder().encode(data), as: UTF8.self)

                let db = try Connection(self.dbPath)

                let saves = Table("saves")
                let id = Expression<String>("id")
                let json = Expression<String?>("json")

                try db.transaction {
                    let savedItem = saves.filter(id == key)
                    if try db.scalar(savedItem.count) == 0 {
                        let insert = saves.insert(id <- key, json <- jsonString)
                        try db.run(insert)
                    } else {
                        try db.run(savedItem.update(json <- jsonString))
                    }

                    let lastSavedItem = saves.filter(id == "last")
                    if try db.scalar(lastSavedItem.count) == 0 {
                        let insert = saves.insert(id <- "last", json <- jsonString)
                        try db.run(insert)
                    } else {
                        try db.run(lastSavedItem.update(json <- jsonString))
                    }
                }
            } catch {
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
        return load(key: "last")
    }

    func load(key: String) -> Data? {
        do {
            self.initDBIfNeeded()

            let db = try Connection(self.dbPath)
            let saves = Table("saves")
            let id = Expression<String>("id")
            let json = Expression<String?>("json")

            let savedItem = saves.filter(id == key)
            for item in try db.prepare(savedItem) {
                if let str = item[json] {
                    if let d = str.data(using: .utf8) {
                        return try JSONDecoder().decode(Data.self, from: d)
                    }
                }
            }
        } catch {
        }
        return nil
    }
}
