module Tools

using ..Types

function filter_dict!(filter_dict, filter_value=nothing)
    if isa(filter_dict, AbstractDict)
        for (key, val) ∈ filter_dict
            if val == filter_value
                delete!(request, key)
            else
                filter_dict!(val)
            end
        end
    elseif isa(filter_dict, Vector)
        for i ∈ filter_dict
            filter_dict!(i)
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

end