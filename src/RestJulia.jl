module RestJulia

using HTTP

export HTTP

macro register(r, method, scheme, host, path, handler)
    return generate_gethandler(r, method, scheme, host, path, handler)
end

end