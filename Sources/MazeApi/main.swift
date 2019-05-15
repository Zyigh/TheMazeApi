import Foundation
import Kitura
import HeliumLogger
import KituraCompression

HeliumLogger.use()

Setup.setDb()

let router = Router()

router.all(middleware: Compression())

router.get("/") {
    _, response, _ in

    do {
        try response.send("Hello").end()
    } catch let e {
        print(e.localizedDescription)
    }
}

router.get("/group/:group") {
    request, response, next in

    guard let group = request.parameters["group"] else {
        next()
        return
    }

    Group.Persistence.getOne(group, from: Connexion.database) {
        group, error in

        guard nil == error else {
            print(String(describing: error))
            response.status(.notFound)
            return
        }

        do {
            try response.send(group).end()
            next()
        } catch let e {
            print(String(describing: e))
            response.status(.internalServerError)
            return
        }
    }
}

router.post("/group/:group") {
    request, response, next in

    guard let groupName = request.parameters["group"],
          let data = request.body?.asRaw,
          let user = try? JSONDecoder().decode(User.self, from: data) else {
        print("/group/:group doesn't handle body given")
        next()
        return
    }

    Group.Persistence.getOne(groupName, from: Connexion.database) {
        group, error in

        guard nil == error else {
            response.status(.internalServerError)
            return
        }

        let group = group ?? Group(_id: groupName, _rev: nil, users: [user])
        Group.Persistence.save(group, to: Connexion.database) {
            updated, error in

            guard nil == error else {
                print(String(describing: error))
                return
            }

            do {
                try response.send(updated).end()
                next()
            } catch let e {
                print(String(describing: e))
                response.status(.internalServerError)
                return
            }
        }
    }
}

router.post("/:group/add/:user") {
    request, response, next in

    guard let group = request.parameters["group"], 
          let user = request.parameters["user"] else {
        next()
        return
    }

    Group.Persistence.getOne(group, from: Connexion.database) {
        g, e in

        var status: HTTPStatusCode = .notFound

        guard nil == e else {
            response.status(.internalServerError)
            return
        }

        if var g = g {
            status = .OK

            if g.users.map({$0._id}).filter({$0 == user}).count > 0 {
                status = .badRequest
            } else {
                g.users.append(User(_id: user, _rev: nil, hiscore: 0))
                Group.Persistence.save(g, to: Connexion.database) {
                    g, e in

                    if nil != e {
                        status = .internalServerError
                    }
                }
            }
        }

        do {
            try response.status(status).end()
            next()
        } catch let e {
            response.status(.internalServerError)
            next()
        }
    }
}

Kitura.addHTTPServer(onPort: 80, with: router)
Kitura.run()
