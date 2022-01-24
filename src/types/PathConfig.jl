Base.@kwdef mutable struct PathOpenApiConfig
    tags::Union{Nothing, Vector{String}} = nothing
    summary::Union{String, Nothing} = nothing
    description::Union{String, Nothing} = nothing
    operationId::Union{String, Nothing} = nothing
end

Base.@kwdef mutable struct PathConfig
    handler::Function
    method::String = "GET"
    scheme::String = ""
    host::String = ""
    path::String = ""
    openapi_config::PathOpenApiConfig = PathOpenApiConfig()
end