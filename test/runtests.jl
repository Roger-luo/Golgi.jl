using Golgi
using Test

@testset "Golgi.jl" begin
    # Write your tests here.
end

using Enzyme
using ChainRules
Enzyme.pullback(sin, 2.0)(1.0)
@time Enzyme.pullback(tanh, 2.0)(1.0)
ChainRules.rrule(sin, 2.0)[2](1.0)

f(x) = cos(sin(x))

Golgi.rrule_call(f, 2.0)
Golgi.rrule_call(sin, 2.0)


foo(x) = x
ChainRules.rrule(foo, 2.0)

using Enzyme

struct Foo
    x::Float64
end

function (f::Foo)(x::Float64)
    return f.x + x
end

Enzyme.pullback(Foo(1.0), 2.0)(1.0)


@generated function goo(xs...)
    quote
        return $(xs)
    end
end

@generated function foo(x)
    quote
        goo(x)
    end
end

using Zygote

Zygote.pullback(sin, 2.0)
goo(1, 2, 3.0)

function rrule(::Type{f}, args...) where {f <: Operation}
end

function rrule(::Type{typeof(apply!)}, r::AbstractRegister, op::Operation)
    apply!(r, op), function pullback(Δ)
        reverse_r, grad = Δ
        apply!(reverse_r, adjoint(op))
        # ...
        # NOTE: grad_op is of type ∇Operation
        # which is a struct contains same field
        # of Operation, but are gradients of the fields
        return NoTangent(), grad_r, grad_op
    end
end

function rrule(f::Type{F}, args...) where {F <: Operation}
    f(args...), function pullback(Δ::∇Operation)
        return unpack(Δ) # unpack the struct back to a Tuple in argument order
    end
end

# this only works when return value is an expectation or measure
# error when return value is not a Real
# how do we extract expectation loops from function body?
# canonicalize measure accumulation like for _ in 1:1000::UnitRange; measure end? but how
function frule((∇self, ∇r, ∇op), ::Type{typeof(apply!)}, r::AbstractRegister, op::Operation)
    apply!(r, op)
    # ∇r can be NoTangent() if compile target is a quantum device
    # how do we add/sub pi/2 in the IR?
end
