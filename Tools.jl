module Tools

using ..Types, ..RestJulia, JSON3

function filter_dict!(filter_dict, filter_value=nothing)
    if isa(filter_dict, AbstractDict)
        for (key, val) ∈ filter_dict
            if val == filter_value
                delete!(filter_dict, key)
            else
                filter_dict!(val, filter_value)
            end
        end
    elseif isa(filter_dict, Vector)
        for i ∈ filter_dict
            filter_dict!(i, filter_value)
        end
    end
end

function method_argnames(m::Method)
    argnames = ccall(:jl_uncompress_argnames, Vector{Symbol}, (Any,), m.slot_syms)
    isempty(argnames) && return argnames
    return argnames[1:m.nargs]
end

function method_argnames_argtypes(m::Method)
    arg_names = method_argnames(m)[2:end]
    arg_types = [i for i ∈ m.sig.parameters[2:end]]
    return arg_names, arg_types
end

function save_config(path="config.json")
    local_conf = deepcopy(RestJulia.openapi_config)
    filter_dict!(local_conf)
    open(path, "w") do io
        JSON3.pretty(io, local_conf)
    end
end

function get_types_union(union_type, type_list=[])
    push!(type_list, union_type.a)
    if isa(union_type.b, Union)
        get_types_union(union_type.b, type_list)
    else
        push!(type_list, union_type.b)
        return type_list
    end
end

end