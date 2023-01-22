module RestJulia

using HTTP, JSON3

include("types/Types.jl")
using .Types

include("modules/Tools.jl")
using .Tools

include("modules/OpenApi.jl")
using .OpenApi

export HTTP, PathConfig, @register_type

openapi_config = nothing

function initialize(title::String; version::String="1.0", description::String="A Webservice created with RestJulia", openapi_version::String="3.0.0", )::HTTP.Router
    global openapi_config
    
    openapi_config = Dict(
        "openapi" => openapi_version,
        "info" => Dict(
            "title" => title,
            "version" => version,
            "description" => description
        ),
        "paths" => Dict(),
        "components" => Dict(
            "schemas" => Dict()
        )
    )

    return HTTP.Router();
end

function generate_path_handler(path::String, handler::Function)::Nothing
    handler_name = Symbol(handler)
    handler_methods = collect(methods(handler))
    #@assert length(handler_methods) == 1 "More than one handler defined for method $handler_name"
    handler_method = handler_methods[1]
    arg_names, arg_types = Tools.method_argnames_argtypes(handler_method)

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
            
            args = Any[]

            for (index, type) ∈ enumerate(arg_types)
                arg_found = false
                arg_name = arg_names[index]
                concrete_types = type isa Union ? Tools.get_types_union(type) : [type]
                for (name, arg) ∈ arg_pairs
                    if name == arg_name
                        @show concrete_types
                        for concrete_type ∈ [i for i ∈ concrete_types if i ≠ Nothing]

                            parsed_arg = isa(arg, concrete_type) ? arg : tryparse(concrete_type, arg)
                            @show parsed_arg
                            if !isnothing(parsed_arg)
                                arg_found = true
                                push!(args, parsed_arg)
                                break
                            end
                        end
                        if !arg_found
                            return HTTP.Response(400, "Argument '$arg_name' must be one of the types '$concrete_types' ('$arg' given)")
                        end
                    end
                end
                
                if !arg_found
                    if Nothing ∈ concrete_types
                        push!(args, nothing)
                    else    
                        return HTTP.Response(400, "Argument '$arg_name' is missing!")
                    end
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

    return nothing
end

function register(r, config::Types.PathConfig)::Nothing
    global openapi_config

    generate_path_handler(config.path, config.handler)
    
    existing_config = config.path ∈ keys(openapi_config["paths"]) ? openapi_config["paths"][config.path] : nothing
    openapi_config["paths"][config.path] = OpenApi.PathItemObject(config, existing_config)

    method = config.method
    path = config.path
    handler = config.handler

    reg_quote = quote
        local local_path = $path
        adapted_path = replace(local_path, r"\{(.*?)\}" => "*")
        HTTP.register!($r, $method, adapted_path, $handler)    
    end

    eval(reg_quote)

    return nothing
end

end