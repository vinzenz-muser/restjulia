using ..JSON3, StructTypes

Base.@kwdef mutable struct RefObject
    ref::String
end

Base.@kwdef mutable struct SchemaObject
    type::Symbol
    required::Union{Vector{Symbol}, Nothing}
    nullable::Bool
    default::Any
    properties::Union{Nothing, Dict{Symbol, SchemaObject}} = nothing
end

Base.@kwdef mutable struct ParameterObject
    name::String = ""
    in::String = ""
    description::Union{String, Nothing} = nothing
    required::Union{Nothing, Bool} = nothing
    schema::Union{Nothing, Union{SchemaObject, RefObject}} = nothing
end

Base.@kwdef mutable struct MediaTypeObject
    schema::SchemaObject
end

Base.@kwdef mutable struct ResponseObject
    description::String
    content::MediaTypeObject
end

Base.@kwdef mutable struct OperationObject
    summmary::Union{String, Nothing} = nothing
    parameters::Union{ParameterObject, Nothing} = nothing
    responses::Dict{String, ResponseObject}
end

Base.@kwdef mutable struct PathItemObject
    get::Union{OperationObject, Nothing} = nothing 
    post::Union{OperationObject, Nothing} = nothing
    put::Union{OperationObject, Nothing} = nothing
    delete::Union{OperationObject, Nothing} = nothing
end

Base.@kwdef mutable struct InfoObject
    title::String
    version::String
end

Base.@kwdef mutable struct OpenAPIObject
    openapi::String
    info::InfoObject
    paths::Dict{String, PathItemObject}
end

defaults = Dict(
    String => Dict(
        :value => "",
        :type => "string"
    ),
    Float64 => Dict(
        :value => 0.0,
        :type => "float",
        :format => "float64"
    ),
    Float32 => Dict(
        :value => 0.0,
        :type => "float",
        :format => "float32"
    ),
    Int64 => Dict(
        :value => 0.0,
        :type => "integer",
        :format => "int64"
    ),
    Int32 => Dict(
        :value => 0.0,
        :type => "integer",
        :format => "int32"
    )
)

function get_schema_name(variable_expr::Expr)::Symbol
    if typeof(variable_expr.args[1]) == Bool
        return variable_expr.args[2]
    end

    has_default = typeof(variable_expr.args[1]) == Expr
    
    if has_default
        variable_name = variable_expr.args[1].args[1]
    else
        variable_name = variable_expr.args[1]
    end

    return variable_name
end

function get_necessary_args(d::DataType, args_list=Dict())
    try
        d(;args_list...)
    catch e
        field_names = fieldnames(d)
        field_types = fieldtypes(d)
        failed_variable = e.var
        failed_index = findfirst(x->x==failed_variable, field_names)
        failed_type = field_types[failed_index]

        if typeof(failed_type) == Union
            non_nothing_index = findfirst(x -> x!=Nothing, Base.uniontypes(failed_type))
            failed_type = Base.uniontypes(failed_type)[non_nothing_index]
        end

        default_value = get_instance(failed_type)[1]
        args_list[failed_variable] = default_value
        get_necessary_args(d, args_list)
    end
    return args_list
end

function get_instance(d::DataType)
    if d in keys(defaults)
        return defaults[d][:value], Dict()
    end

    necessary_args = get_necessary_args(d)
    instance = d(;necessary_args...)
    return instance, necessary_args
end

function SchemaObject(d::Union{DataType,Union})
    required=nothing    
    nullable = false
    default=nothing

    if typeof(d) == Union
        nullable = true
        non_nothing_index = findfirst(x -> x!=Nothing, Base.uniontypes(d))
        d = Base.uniontypes(d)[non_nothing_index]
    end


    if d in keys(defaults)
        type=Symbol(d)
        nullable=nullable
        properties=nothing      
    else 
        required = Symbol[]
        instance, necessary_args = get_instance(d)
        properties = Dict{Symbol, Union{SchemaObject, RefObject}}()

        for (fname, ftype) in zip(fieldnames(d), fieldtypes(d))

            schema_object = SchemaObject(ftype)

            if fname in keys(necessary_args)
                push!(required, fname)
            else
                default_value = getfield(instance, fname)

                if isnothing(default_value)
                    default_value = "null"
                end

                schema_object.default = default_value
            end

            properties[fname] = schema_object
        end

        type=:object
        nullable=nullable
        default=Nothing
    end

    return SchemaObject(
        type=type,
        required=required,
        nullable=nullable,
        default=default,
        properties=properties
    )
end

function clean_dict!(d)
    return 
end

function clean_dict!(d::Vector)
    for i in d
        clean_dict!(i)
    end
end

function clean_dict!(d::Dict)
    for (key, val) in d
        if isnothing(val)
            delete!(d, key)
        else
            clean_dict!(val)
        end
    end
end

function clean_dict!(o::SchemaObject)::Dict
    d = copy(JSON3.read(JSON3.write(o)))
    clean_dict!(d)
    return d
end

Base.show(io::IO, obj::SchemaObject) = println(io, JSON3.pretty(clean_dict!(obj)));