module RestJulia

using HTTP, JSON3

include("types/Types.jl")
using .Types

export HTTP

openapi_config = nothing

function initialize(title::String; version::String="1.0", description::String="A Webservice created with RestJulia", openapi_version::String="3.0.0", )
    global openapi_config
    
    paths = Dict{String, Types.PathItemObject}()
    openapi_config = Types.OpenAPIObject(
        openapi_version,
        Types.InfoObject(title, description, version),
        paths
    )

    return HTTP.Router();
end

function method_argnames(m::Method)
    argnames = ccall(:jl_uncompress_argnames, Vector{Symbol}, (Any,), m.slot_syms)
    isempty(argnames) && return argnames
    return argnames[1:m.nargs]
end

function get_argnames_argtypes(m::Method)
    arg_names = method_argnames(m)[2:end]
    arg_types = [i for i ∈ m.sig.parameters[2:end]]
    return arg_names, arg_types
end

function generate_path_handler(path::String, handler)
    handler_name = Symbol(handler)
    handler_methods = collect(methods(handler))
    #@assert length(handler_methods) == 1 "More than one handler defined for method $handler_name"
    handler_method = handler_methods[1]
    arg_names, arg_types = get_argnames_argtypes(handler_method)

    req_handler = quote
        function Main.$handler_name(r)
            args_split = HTTP.URIs.splitpath(r.target)
            uri = HTTP.URIs.URI(r.target)
            
            arg_names = $arg_names
            arg_types = $arg_types
            
            arg_pairs = Tuple{Symbol, Any}[]
            
            path_split = HTTP.URIs.splitpath($path)
            for (i,path) ∈ enumerate(path_split)
                if path[1:1] == "{"
                    push!(arg_pairs, (Symbol(path[2:end-1]), args_split[i]))
                end
            end 

            for (key, val) ∈ HTTP.URIs.queryparams(uri)
                push!(arg_pairs, (Symbol(key), val))
            end
            
            args = []

            for (index, type) ∈ enumerate(arg_types)
                arg_found = false
                arg_name = arg_names[index]
                for (name, arg) ∈ arg_pairs
                    if name == arg_name
                        try
                            parsed_arg = isa(arg, type) ? arg : parse(type, arg)
                            push!(args, parsed_arg)
                            arg_found = true
                            break
                        catch
                            return HTTP.Response(400, "Argument '$arg_name' must be of type '$type' ('$arg' given)")
                        end
                    end
                end
                
                if !arg_found
                    return HTTP.Response(400, "Argument '$arg_name' is missing!")
                end
            end

            try 
                return HTTP.Response(200, JSON3.write($handler(args...)))
            catch e
                s = IOBuffer()
                errormsg = String(resize!(s.data, s.size))
                return HTTP.Response(500, "Runtime Error: $e")
            end
        end
    end

    eval(req_handler)

    return
end

function generate_path_item(config)::Types.PathItemObject
    path_item = Types.PathItemObject()
    handler_methods = collect(methods(config.handler))
    ans = Types.PathItemObject()
    ans.get = Types.OperationObject()
    
    arg_names, arg_types = get_argnames_argtypes(handler_methods[1])

    parameters = Types.ParameterObject[]
    path_split = HTTP.URIs.splitpath(config.path)

    for (i,path) ∈ enumerate(path_split)
        if path[1:1] == "{"
            parameter_object = Types.ParameterObject()
            parameter_object.name = path[2:end-1] 
            parameter_object.in = "path"
            parameter_object.required = true
            arg_name = Symbol(path[2:end-1])
            for (i, function_arg_name) in enumerate(arg_names)
                if arg_name == function_arg_name
                    arg_type = arg_types[i]
                    parameter_object.schema = Dict(
                        "type" => "integer",
                        "format" => string(typeof(arg_type))
                    )
                end
            end
            push!(parameters, parameter_object)
        end
    end 
    ans.parameters = parameters
    return ans
end

function register(r, config::Types.Path)
    global openapi_config

    generate_path_handler(config.path, config.handler)
    method = config.method
    scheme = config.scheme
    host = config.host
    path = config.path
    handler = config.handler
    
    openapi_config.paths[config.path] = generate_path_item(config)

    reg_quote = quote
        local local_path = $path
        adapted_path = replace(local_path, r"\{(.*?)\}" => "*")
        println(adapted_path)
        HTTP.@register($r, $method, $scheme, $host, adapted_path, $handler)    
    end

    eval(reg_quote)

    return
end

function register(r, method, scheme, host, path, handler)
    path_config = Types.Path(
        handler = handler
    )
    path_config.method = method
    path_config.scheme = scheme
    path_config.host = host
    path_config.path = path

    register(r, path_config)
end

end