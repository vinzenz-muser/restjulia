using StructTypes

Base.@kwdef mutable struct ParameterObject
    name::String = ""
    in::String = ""
    description::Union{String, Nothing} = nothing
    required::Bool = false
    schema::Union{Nothing, Dict} = nothing
end
StructTypes.StructType(::Type{ParameterObject}) = StructTypes.Mutable()

Base.@kwdef mutable struct MediaTypeObject
    schema::Union{Nothing, Dict} = nothing
    examples::Dict{String, Dict} = Dict{String, Dict}()
end
StructTypes.StructType(::Type{MediaTypeObject}) = StructTypes.Mutable()

Base.@kwdef mutable struct ResponseObject
    description::String = ""
    content::Dict{String, MediaTypeObject} = Dict{String, MediaTypeObject}()
end
StructTypes.StructType(::Type{ResponseObject}) = StructTypes.Mutable()

Base.@kwdef mutable struct RequestBodyObject
    description::Union{Nothing, String} = ""
    content::Union{Nothing, Dict} = nothing
end
StructTypes.StructType(::Type{RequestBodyObject}) = StructTypes.Mutable()

Base.@kwdef mutable struct OperationObject
    responses::Dict{Union{String, Int64}, ResponseObject} = Dict(200 => ResponseObject())
    tags::Vector{String} = String[]
    summary::Union{Nothing, String} = nothing
    description::Union{Nothing, String} = nothing
    parameters::Vector{Union{ParameterObject, Dict}} = Dict[]
    requestBody::Union{RequestBodyObject, Dict, Nothing} = nothing
end   
StructTypes.StructType(::Type{OperationObject}) = StructTypes.Mutable()

Base.@kwdef mutable struct InfoObject
    title::String
    description::Union{String, Nothing}
    version::String
end
StructTypes.StructType(::Type{InfoObject}) = StructTypes.Mutable()

Base.@kwdef mutable struct PathItemObject
    summary::Union{String, Nothing} = nothing
    description::Union{String, Nothing} = nothing
    get::Union{Nothing, OperationObject} = nothing
    put::Union{Nothing, OperationObject} = nothing
    post::Union{Nothing, OperationObject} = nothing
    delete::Union{Nothing, OperationObject} = nothing
    options::Union{Nothing, OperationObject} = nothing
    head::Union{Nothing, OperationObject} = nothing
    path::Union{Nothing, OperationObject} = nothing
    trace::Union{Nothing, OperationObject} = nothing
    parameters::Vector{Union{ParameterObject, Dict}} = ParameterObject[]
end
StructTypes.StructType(::Type{PathItemObject}) = StructTypes.Mutable()

Base.@kwdef mutable struct OpenAPIObject
    openapi::String
    info::InfoObject
    paths::Dict{String, PathItemObject}
end   
StructTypes.StructType(::Type{OpenAPIObject}) = StructTypes.Mutable()

Base.@kwdef mutable struct PathObject
    description::Union{Nothing, String} = nothing
end 
StructTypes.StructType(::Type{PathObject}) = StructTypes.Mutable()
