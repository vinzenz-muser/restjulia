using RestJulia, JSON3, StructTypes, Dates

const router = RestJulia.initialize("title";)

Base.@kwdef mutable struct CustomNest
    custom_string::String = ""
end

Base.@kwdef mutable struct CustomRequest
    custom_string::String = ""
    custom_nest::CustomNest = CustomNest()
    custom_int::Int64 = 0
end

Base.@kwdef mutable struct PathResponse
    custom_string::String = ""
    custom_nest::CustomNest = CustomNest()
    custom_int::Int64 = 0
end

Base.@kwdef mutable struct JsonResponse
    custom_string::String = ""
    custom_nest::CustomNest = CustomNest()
    custom_int::Int64 = 0
end

StructTypes.StructType(::Type{CustomRequest}) = StructTypes.Mutable()
StructTypes.StructType(::Type{CustomNest}) = StructTypes.Mutable()
StructTypes.StructType(::Type{PathResponse}) = StructTypes.Mutable()
StructTypes.StructType(::Type{JsonResponse}) = StructTypes.Mutable()

function test_path(test_int::Int64, test_float::Float64, test_string::String)::PathResponse
    ans = PathResponse()
    ans.custom_string = test_string
    ans.custom_int = test_int
    return ans
end

function test_json(json_body::CustomRequest, test_int::Int64)::JsonResponse
    ans = JsonResponse()
    ans.custom_int = test_int
    ans.custom_string = "Test"
    return ans
end

function requestHandler(req)
    start = Dates.now(Dates.UTC)
    response = HTTP.handle(router, req)
    stop = Dates.now(Dates.UTC)
    @info (event="RequestEnd", duration=Dates.value(stop - start))
    return response
end

RestJulia.register(router, "POST", "", "", "/test_path/{test_string}/asdf/{test_float}", test_path)
RestJulia.register(router, "POST", "", "", "/test_json", test_json)

open("my_new_file.json", "w") do io
    JSON3.write(io, RestJulia.openapi_config)
end

HTTP.serve(requestHandler, "0.0.0.0",  5001)