//
//  Storage.swift
//  nonogram
//
//  Created by Denis S. Morozov on 13.01.2023.
//

import Foundation
import SQLite

final class Storage {

    private struct SavesTableDefinition {
        static let table = Table("saves")
        static let id = Expression<String>("id")
        static let json = Expression<String>("json")
        static let modifiedDate = Expression<Date>("modifiedDate")
        private init() { }
    }

    struct Data: Codable {
        let url: URL
        let thumbnail: URL
        let title: String
        let field: Field
        let layers: [String: Field]
        let selectedLayerColor: Field.Color?
        let solution: [[Int]]
        let colors: [Field.Color]
        let showsErrors: Bool
    }

    private lazy var dbPath: String = {
        func getDocumentsDirectory() -> URL {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let documentsDirectory = paths[0]
            return documentsDirectory
        }

        return getDocumentsDirectory().appendingPathComponent("db_2.sqlite3").path
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

            try db.run(SavesTableDefinition.table.create { t in
                t.column(SavesTableDefinition.id, primaryKey: true)
                t.column(SavesTableDefinition.json)
                t.column(SavesTableDefinition.modifiedDate)
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
              colors: [Field.Color],
              showsErrors: Bool
    ) {
        let data = Data(
            url: url,
            thumbnail: thumbnailUrl,
            title: title,
            field: field,
            layers: layers,
            selectedLayerColor: selectedLayerColor,
            solution: solution,
            colors: colors,
            showsErrors: showsErrors
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

                let saves = SavesTableDefinition.table
                let id = SavesTableDefinition.id
                let json = SavesTableDefinition.json
                let modifiedDate = SavesTableDefinition.modifiedDate

                let savedItem = saves.filter(id == key)
                if try db.scalar(savedItem.count) == 0 {
                    let insert = saves.insert(id <- key, json <- jsonString, modifiedDate <- Date())
                    try db.run(insert)
                } else {
                    try db.run(savedItem.update(json <- jsonString, modifiedDate <- Date()))
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
        return _load(key: nil)
    }

    func load(key: String) -> Data? {
        return _load(key: key)
    }

    private func _load(key: String?) -> Data? {
        do {
            self.initDBIfNeeded()

            let db = try Connection(self.dbPath)

            let saves = SavesTableDefinition.table
            let id = SavesTableDefinition.id
            let json = SavesTableDefinition.json
            let modifiedDate = SavesTableDefinition.modifiedDate

            let savedItem: QueryType
            if let key {
                savedItem = saves.filter(id == key)
            } else {
                savedItem = saves.order(modifiedDate.desc)
            }
            for item in try db.prepare(savedItem) {
                let str = item[json]
                if let d = str.data(using: .utf8) {
                    return try JSONDecoder().decode(Data.self, from: d)
                }
            }
        } catch {
        }
        return nil
    }
}
