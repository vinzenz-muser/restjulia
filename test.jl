using RestJulia, JSON3, Dates

const router = RestJulia.initialize("title")

@register_type mutable struct CustomNest
    custom_string::String = ""
    custom_non_default::Int64
    custom_nullable::Union{String, Nothing}
    custom_nullable_default::Union{String, Nothing} = nothing
end

type = RestJulia.Types.SchemaObject(CustomNest)

@register_type mutable struct CustomRequest
    custom_string::String = ""
    custom_nest::CustomNest
    custom_int::Int64 = 0
end

@register_type mutable struct PathResponse
    custom_string::String = ""
    custom_nest::CustomNest = CustomNest()
    custom_int::Int64 = 0
end

@register_type mutable struct JsonResponse
    custom_string::String = ""
    custom_nest::CustomNest = CustomNest()
    custom_int::Int64 = 0
end

#StructTypes.StructType(::Type{CustomRequest}) = StructTypes.Mutable()
#StructTypes.StructType(::Type{CustomNest}) = StructTypes.Mutable()
#StructTypes.StructType(::Type{PathResponse}) = StructTypes.Mutable()
#StructTypes.StructType(::Type{JsonResponse}) = StructTypes.Mutable()

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

config_test_path = PathConfig(handler=test_path, path="/test_path/{test_string}/asdf/{test_float}")
config_test_json = PathConfig(handler=test_json, method="POST", path="/test_json")

RestJulia.register(router, config_test_path)
RestJulia.register(router, config_test_json)

open("config.json", "w") do io
    JSON3.pretty(io, RestJulia.openapi_config, JSON3.AlignmentContext(alignment=:Left, indent=4))
end


HTTP.serve(requestHandler, "0.0.0.0",  5001)