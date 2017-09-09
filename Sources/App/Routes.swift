import Vapor
import AuthProvider
import Sessions
import HTTP

final class Routes: RouteCollection {
    let view: ViewRenderer
    
    //route builder for protected routes
    let authRoutes : RouteBuilder
    //route builder for login routes
    let loginRouteBuilder : RouteBuilder
    // 1. we need a reference to our droplet to create the routes
    init(_ view: ViewRenderer,_ drop: Droplet) {
        //this stays the same
        self.view = view
        
        //create a password middleware with our user
        let passwordMiddleware = PasswordAuthenticationMiddleware(User.self)
        //create a memory storage for our sessions
        let memory = MemorySessions()
        //create the persis middleware with our User
        let persistMiddleware = PersistMiddleware(User.self)
        //create the sessions middleware with our memory
        let sessionsMiddleware = SessionsMiddleware(memory)
        
        //2. now that we have instantiated everthing, all we need to do is create two routes.
        // the first route is for password protected routes
        self.authRoutes = drop.grouped([sessionsMiddleware, persistMiddleware, passwordMiddleware])
        // the second one is to login, We need this route to have the sessions and persist middleware in place to store
        // that a user has logged in and give him a vapor access token which he can use in the upcoming requests
        self.loginRouteBuilder = drop.grouped([sessionsMiddleware, persistMiddleware])
    }
    
    func build(_ builder: RouteBuilder) throws {
        /// GET /
        builder.get { req in
            return try self.view.make("welcome")
        }
        
        builder.get("register") { req in
            return try self.view.make("register")
        }
        
        //1. Modify this controller to be built by "authRoutes" to protect all it's routes
        /// GET /hello/...
        authRoutes.resource("hello", HelloController(view))
        
        //2. create the login route
        builder.get("login") { req in
            return try self.view.make("login")
        }
        
        //3. implement the login logic, built by the "loginRouteBuilder" so our session is persisted
        loginRouteBuilder.post("login") { req in
            guard let email =  req.formURLEncoded?["email"]?.string,
                let password =  req.formURLEncoded?["password"]?.string else {
                    return "Bad credentials"
            }
            //create a Password object with email and password
            let credentials = Password(username: email, password: password)
            
            //User.authenticate queries the user by username and password and informs the middlewar that this user is now authenticated
            //the middleware creates a session token, ties it to the user and sends it in a cookie to the client.
            //the requests done with this request token automatically are authenticated with this user.
            let user = try User.authenticate(credentials)
            req.auth.authenticate(user)
            
            //redirect to the protected route /hello
            return Response(redirect: "hello")
        }
        
        builder.post("register") { req in
            if  let name = req.formURLEncoded?["name"]?.string,
                !name.isEmpty,
                let email = req.formURLEncoded?["email"]?.string,
                !email.isEmpty,
                let password = req.formURLEncoded?["password"]?.string,
                !password.isEmpty{
                
                
                let user = User(name: name, email: email, password: password)
                try user.save()
            }
            
            return "success"
        }
        
        // response to requests to /info domain
        // with a description of the request
        builder.get("info") { req in
            return req.description
        }
        
    }
}
