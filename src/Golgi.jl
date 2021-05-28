module Golgi

using Enzyme
using Zygote
using ChainRules
using CompilerPluginTools

@generated function rrule_call(f, args...)
    transform = find_heuristic_best_transform(f, args)
    return quote
        rrule_call($transform, f, args...)
    end
end

abstract type CompilerTransform end

struct NativeTransform <: CompilerTransform end
struct EnzymeTransform <: CompilerTransform end
struct YaoTransform <: CompilerTransform end
struct GenTransform <: CompilerTransform end
struct ChainRulesTransform <: CompilerTransform end

# defines the intrinsic/entry of the eDSL compiler transform
# when fallback to the glue compiler implementation
# it is always true, but of course this is gonna be
# generating slower code, but who cares
is_entry_of(::NativeTransform, f, tt) = true

function is_entry_of(::ChainRulesTransform, f, tt::Tuple)
    rrule_rettype = Core.Compiler.return_type(ChainRules.rrule, Tuple{f, tt...})
    return !(rrule_rettype === Nothing)
end

# TODO: check on Yao's quantum program entry
function is_entry_of(::YaoTransform, f, tt::Tuple)
    return false
end

# function is_entry_of(::GenTransform, f, tt)
# end

function is_entry_of(::EnzymeTransform, f, tt::Tuple)
    return f <: Function
end

function find_heuristic_best_transform(f, tt)
    is_entry_of(ChainRulesTransform(), f, tt) && return ChainRulesTransform()
    # is_entry_of(YaoTransform(), f, tt) && return YaoTransform()
    is_entry_of(EnzymeTransform(), f, tt) && return EnzymeTransform()
    return NativeTransform()
end

function rrule_call(::ChainRulesTransform, f, args...)
    return ChainRules.rrule(f, args...)
end

function rrule_call(::NativeTransform, f, args...)
    Zygote.pullback(f, args...)
end

# wrap enzyme to respect ChainRules convention
# NOTE: we don't handle Julia callable struct
# in Enzyme - until it works in Enzyme natively
function rrule_call(::EnzymeTransform, f::Function, args...)
    f(args...), function enzyme_pullback(Δ)
        grad = Enzyme.pullback(f, args...)(Δ)
        return (ZeroTangent(), grad...)
    end
end

end
