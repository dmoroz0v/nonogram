//
//  Storage.swift
//  nonogram
//
//  Created by Denis S. Morozov on 13.01.2023.
//

import Foundation
import SQLite

final class Storage {

    private enum State {
        case saving, pendingData(Data)
    }

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

    private lazy var dbUrl: URL = {
        func getDocumentsDirectory() -> URL {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let documentsDirectory = paths[0]
            return documentsDirectory
        }

        return getDocumentsDirectory().appendingPathComponent("db_2.sqlite3")
    }()

    private var state: [String: State] = [:]

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
        if case .saving = state[key] {
            state[key] = .pendingData(data)
            return
        }
        save(data, key: key)
    }

    func loadLast() -> Data? {
        return _load(key: nil)
    }

    func load(key: String) -> Data? {
        return _load(key: key)
    }

    private func initDBIfNeeded() {
        let needsInitDB = !FileManager.default.fileExists(atPath: dbUrl.path)
        if needsInitDB {
            FileManager.default.createFile(atPath: dbUrl.path, contents: .init())
            do {
                let db = try Connection(dbUrl.path)

                try db.run(SavesTableDefinition.table.create { t in
                    t.column(SavesTableDefinition.id, primaryKey: true)
                    t.column(SavesTableDefinition.json)
                    t.column(SavesTableDefinition.modifiedDate)
                })
            } catch {
            }
        }
    }

    private func save(_ data: Data, key: String) {
        state[key] = .saving
        DispatchQueue.global().async {
            do {
                let jsonString = String(decoding: try JSONEncoder().encode(data), as: UTF8.self)

                let saves = SavesTableDefinition.table
                let id = SavesTableDefinition.id
                let json = SavesTableDefinition.json
                let modifiedDate = SavesTableDefinition.modifiedDate

                let savedItem = saves.filter(id == key)

                let db = try Connection(self.dbUrl.path)

                if try db.scalar(savedItem.count) == 0 {
                    let insert = saves.insert(id <- key, json <- jsonString, modifiedDate <- Date())
                    try db.run(insert)
                } else {
                    try db.run(savedItem.update(json <- jsonString, modifiedDate <- Date()))
                }
            } catch {
            }

            DispatchQueue.main.async {
                let stateForKey = self.state[key]
                self.state[key] = nil
                if case .pendingData(let data) = stateForKey {
                    self.save(data, key: key)
                }
            }
        }
    }

    private func _load(key: String?) -> Data? {
        do {
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

            let db = try Connection(self.dbUrl.path)

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
