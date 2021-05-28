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