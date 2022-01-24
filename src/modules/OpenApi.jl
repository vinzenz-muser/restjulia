module OpenApi

using ..Tools, JSON3, ..Types, ..HTTP

export PathObject


function ParameterObject(arg_name, arg_type, in_str::String; description="")
    ans_obj = Dict()
    ans_obj["name"] = string(arg_name)
    ans_obj["in"] = in_str
    ans_obj["schema"] = Dict(
        "type" => "string"
    )
    
    ans_obj["required"] = true

    if (nothing isa arg_type && in_str != "path")
        ans_obj["required"] = false
    end
    
    return ans_obj
end

function OperationObject(path_config::PathConfig)
    operation_object = Dict()
    operation_object["description"] = path_config.openapi_config.description
    operation_object["summary"] = path_config.openapi_config.summary
    operation_object["responses"] = Dict{Int64, Dict}()
    operation_object["responses"][200] = Dict("description" => "success")
    return operation_object
end

function PathItemObject(path_config::PathConfig,  path_item::Union{Dict, Nothing}=nothing)
    if isnothing(path_item)
        path_item = Dict()
    end

    handler = path_config.handler
    path_item["description"] = path_config.openapi_config.description
    path_item["summary"] = path_config.openapi_config.summary
    operation_object = OperationObject(path_config)
    handler_methods = collect(methods(handler))
    path_item[lowercase(path_config.method)] = operation_object

    arg_names, arg_types = Tools.method_argnames_argtypes(handler_methods[1])

    uri = HTTP.URIs.URI(path_config.path)
    path_split = HTTP.URIs.splitpath(uri)
    path_args = [Symbol(i[2:end-1]) for i ∈ path_split if i[1:1] == "{"]

    for (i, name) ∈ enumerate(arg_names)
        arg_type = arg_types[i]
        in_str = name ∈ path_args ? "path" : "query"
        if "parameters" ∈ keys(path_item[lowercase(path_config.method)])
            push!(path_item[lowercase(path_config.method)]["parameters"], ParameterObject(name, arg_type, in_str))
        else
            path_item[lowercase(path_config.method)]["parameters"] = [ParameterObject(name, arg_type, in_str)]
        end
    end

    return path_item
end

end