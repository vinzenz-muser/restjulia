using RestJulia

const router = HTTP.Router()

function test(req)
    println(req)
    return "hello"
end

RestJulia.@register(router, "GET", "/test", test)