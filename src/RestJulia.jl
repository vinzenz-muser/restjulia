module RestJulia

using HTTP

export HTTP

macro register(r, method, path, handler)
    print("Hello")
    return HTTP.Handlers.generate_gethandler(r, method, "", "", path, handler)
end

end