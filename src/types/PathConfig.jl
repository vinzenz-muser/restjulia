Base.@kwdef mutable struct PathConfig
    tags::Union{Nothing, Vector{String}} = nothing
    summary::Union{String, Nothing} = nothing
    description::Union{String, Nothing} = nothing
    operationId::Union{String, Nothing} = nothing
end

Base.@kwdef mutable struct Path
    handler::Function
    method::String = "GET"
    scheme::String = ""
    host::String = ""
    path::String = ""
    path_config::PathConfig = PathConfig()
end