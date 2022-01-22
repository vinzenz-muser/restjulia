module openApi

using ..Types


function generate_path_item(config)
    path_item = Types.PathItemObject()
    handler_methods = collect(methods(handler))
    arg_names, arg_types = get_argnames_argtypes(handler_methods[1])

    path_args = []
    path_split = HTTP.URIs.splitpath($path)
    for (i,path) ∈ enumerate(path_split)
        if path[1:1] == "{"
            push!(arg_pairs, (Symbol(path[2:end-1]), args_split[i]))
        end
    end 

    query_args = []

    return path_item
end

end