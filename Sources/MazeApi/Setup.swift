//
// Created by Hugo Medina on 2019-05-15.
//

import Foundation
import CouchDB

class Setup {

    static func setDb() {
        Connexion.client.createDB("groups") {
            db, error in

            guard let db = db,
                    nil == error else {
                print("Groups DB creation not working with error : \(String(describing: error))")
                exit(1)
            }

            Connexion.database = db
        }
    }
}
