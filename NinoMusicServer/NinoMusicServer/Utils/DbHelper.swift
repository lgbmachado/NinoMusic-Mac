//
//  DbHelper.swift
//  NinoMusicServer
//
//  Created by Luiz Guilherme Baptista Machado on 27/01/26.
//

import Foundation
import SQLite3

enum SQLiteError: Error {
    case prepare(message: String)
}

final class DbHelper {

    private var db: OpaquePointer?

    // MARK: - Init

    init?(path: String) {
        if sqlite3_open(path, &db) != SQLITE_OK {
            print("Erro ao abrir banco de dados")
            return nil
        }
    }

    deinit {
        sqlite3_close(db)
    }

    func sql(query: String) throws -> [[String: Any]] {
        var statement: OpaquePointer?
        var result: [[String: Any]] = []
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteError.prepare(message: errorMessage)
        }
        defer {
            sqlite3_finalize(statement)
        }
        while sqlite3_step(statement) == SQLITE_ROW {
            var row: [String: Any] = [:]
            let columnCount = sqlite3_column_count(statement)
            for index in 0..<columnCount {
                let columnName = String(cString: sqlite3_column_name(statement, index))
                let columnType = sqlite3_column_type(statement, index)
                
                switch columnType {
                case SQLITE_INTEGER:
                    row[columnName] = Int(sqlite3_column_int(statement, index))
                case SQLITE_FLOAT:
                    row[columnName] = sqlite3_column_double(statement, index)
                case SQLITE_TEXT:
                    row[columnName] = String(cString: sqlite3_column_text(statement, index))
                case SQLITE_BLOB:
                    let bytes = sqlite3_column_blob(statement, index)
                    let size = sqlite3_column_bytes(statement, index)
                    row[columnName] = Data(bytes: bytes!, count: Int(size))
                case SQLITE_NULL:
                    row[columnName] = nil
                default:
                    row[columnName] = nil
                }
            }
            result.append(row)
        }
        return result
    }
    
    func executeQuery(query: String) -> Bool {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                return true
            }
        }
        sqlite3_finalize(statement)
        return false
    }
    
    func getLastInsertedId() -> Int {
        return Int(sqlite3_last_insert_rowid(db))
    }

    // MARK: - Error helper
    private var errorMessage: String {
        if let error = sqlite3_errmsg(db) {
            return String(cString: error)
        }
        return "Erro desconhecido"
    }
}
