//
//  User.swift
//  Bits
//
//  Created by Benjamin Baumann on 05.09.17.
//

import FluentProvider
import HTTP
import Fluent
import AuthProvider

final class User: Model, PasswordAuthenticatable, SessionPersistable {
    
    let storage = Storage()
    
    var name: String = ""
    var email: String = ""
    var password: String = ""
    
    
    init(name: String, email: String, password: String) {
        self.name = name
        self.email = email
        self.password = password
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set("name",name)
        try row.set("email",email)
        try row.set("password",password)
        return row
    }
    
    required init(row: Row) throws {
            name = try row.get("name")
            email = try row.get("email")
            password = try row.get("password")
    }
}

extension User: Preparation {
    /// Prepares a table/collection in the database
    /// for storing Player
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.string("name")
            builder.string("email")
            builder.string("password")
        }
    }
    /// Undoes what was done in `prepare`
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

// MARK: JSON

// How the model converts from / to JSON.
// For example when:
//     - Creating a new Player
//     - Fetching a Player
//
extension User: JSONConvertible {
    convenience init(json: JSON) throws {
        try self.init(
            name: json.get("name"),
            email: json.get("email"),
            password: json.get("password")
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("id", id)
        try json.set("name",name)
        try json.set("email",email)
        try json.set("password",password)
        return json
    }
}

// MARK: HTTP

// This allows Player models to be returned
// directly in route closures
extension User: ResponseRepresentable { }
