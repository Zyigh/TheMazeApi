//
// Created by Hugo Medina on 2019-05-15.
//

import Foundation
import CouchDB

import Foundation
import CouchDB

struct Group: Document {
    let _id: String?
    var _rev: String?
    var users: [User]
}

struct User: Document {
    let _id: String?
    var _rev: String?
    let hiscore: Int?
}

class Connexion {
//    static let connectionProperties = ConnectionProperties(host: "couch",
//            port: 5984,
//            secured: false)
    static let connectionProperties = ConnectionProperties(host: "couch", port: 5984, secured: false)

    static let client = CouchDBClient(connectionProperties: connectionProperties)
    static var database : Database!
}

extension Group {
    class Persistence {
        // probably useless
        static func getAll(from database: Database, callback:
                @escaping (_ groups: [Group]?, _ error: Error?) -> Void) {
            database.retrieveAll(includeDocuments: true) {
                documents, error in

                guard let documents = documents else {
                    print("Error retrieving all documents: \(String(describing: error))")
                    return callback(nil, error)
                }

                let docs = documents.decodeDocuments(ofType: Group.self)
                callback(docs, nil)
            }
        }

        static func getOne(_ groupId: String, from database: Database, callback: @escaping (_ group: Group?, _ error: Error?) -> Void) {
            database.retrieve(groupId) { (group: Group?, error: CouchDBError?) in
                guard let group = group else {
                    print("Error retrieving document: \(String(describing: error))")
                    return callback(nil, error)
                }

                callback(group, nil)
            }
        }

        // 3
        static func save(_ group: Group, to database: Database, callback:
                @escaping (_ group: Group?, _ error: Error?) -> Void) {
            if let id = group._id, let rev = group._rev {
                database.update(id, rev: rev, document: group) {
                    response, error in

                    guard let response = response, nil == error else {
                        return callback(nil, error)
                    }

                    if response.ok {
                        getOne(group._id ?? "", from: database, callback: callback)
                    } else {
                        callback(nil, error)
                    }
                }
            } else {
                database.create(group) {
                    response, error in

                    guard let response = response, nil == error else {
                        return callback(nil, error)
                    }

                    if response.ok {
                        getOne(group._id ?? "", from: database, callback: callback)
                    } else {
                        callback(nil, error)
                    }
                }
            }
        }


        static func delete(_ groupId: String, from database: Database, callback:
                @escaping (_ error: Error?) -> Void) {
            database.retrieve(groupId) { (group: Group?, error: CouchDBError?) in

                guard let group = group, let groupRev = group._rev else {
                    print("Error retrieving document: \(String(describing:error))")
                    return callback(error)
                }

                database.delete(groupId, rev: groupRev, callback: callback)
            }
        }

    }
}

