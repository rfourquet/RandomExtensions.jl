using RandomExtensions, Random, SparseArrays
using Random: Sampler
using Test

@testset "Distributions" begin
    # Normal/Exponential
    @test rand(Normal()) isa Float64
    @test rand(Normal(0.0, 1.0)) isa Float64
    @test rand(Exponential()) isa Float64
    @test rand(Exponential(1.0)) isa Float64
    @test rand(Normal(Float32)) isa Float32
    @test rand(Exponential(Float32)) isa Float32
    @test rand(Normal(ComplexF64)) isa ComplexF64

    # pairs/complexes
    @test rand(make(Pair, 1:3, Float64)) isa Pair{Int,Float64}
    @test rand(make(Pair{Int8}, 1:3, Float64)) isa Pair{Int8,Float64}
    @test rand(make(Pair{Int8,Float32}, 1:3, Float64)) isa Pair{Int8,Float32}
    @test rand(make(Pair{X,Float32} where X, 1:3, Float64)) isa Pair{Int,Float32}
    @test rand(Pair{Int,Float64}) isa Pair{Int,Float64}

    z = rand(make(Complex, 1:3, 6:9))
    @test z.re ∈ 1:3
    @test z.im ∈ 6:9
    @test z isa Complex{Int}
    z = rand(make(ComplexF64, 1:3, 6:9))
    @test z.re ∈ 1:3
    @test z.im ∈ 6:9
    @test z isa ComplexF64
    for (C, R) in ((Complex, Int), (ComplexF64, Float64), (Complex{Int}, Int))
        z = rand(make(C, 1:3))
        @test z.re ∈ 1:3
        @test z.im ∈ 1:3
        @test z isa Complex{R}
    end
    @test rand(make(Complex, 1:3, Float64)) isa Complex{Float64} # promote_type should be used

    @test rand(ComplexF64) isa ComplexF64

    @test rand(make(Complex,Int), 3) isa Vector{Complex{Int}}
    @test rand(make(Complex,1:3), 3) isa Vector{Complex{Int}}

    # Uniform
    @test rand(Uniform(Float64)) isa Float64
    @test rand(Uniform(1:10)) isa Int
    @test rand(Uniform(1:10)) ∈ 1:10
    @test rand(Uniform(Int)) isa Int

    # Bernoulli
    @test rand(Bernoulli()) ∈ (0, 1)
    @test rand(Bernoulli(1)) == 1
    @test rand(Bernoulli(0)) == 0
    # TODO: do the math to estimate proba of failure:
    @test 620 < count(rand(Bernoulli(Bool, 0.7), 1000)) < 780
    for T = (Bool, Int, Float64, ComplexF64)
        r = rand(Bernoulli(T))
        @test r isa T
        @test r ∈ (0, 1)
        r = rand(Bernoulli(T, 1))
        @test r == 1
    end
end

const rInt8 = typemin(Int8):typemax(Int8)
const spString = Sampler(MersenneTwister, String)

@testset "Containers" for rng in ([], [MersenneTwister(0)], [RandomDevice()])
    # Array
    for T = (Int, Int8)
        for (A, AT) = ((Array, Int8), (Array{T}, T), (Vector, Int8), (Vector{T}, T))
            @inferred rand(rng..., Int8.(1:9), A, 10)
            a = rand(rng..., Int8.(1:9), A, 10)
            @test a isa Vector{AT}
            @test all(in(1:9), a)
            @inferred rand(rng..., Int8, A, 10)
            a = rand(rng..., Int8, A, 10)
            @test a isa Vector{AT}
            @test all(in(rInt8), a)
        end
    end

    # Set
    for S = (Set{Int}, Set, BitSet)
        s = rand(rng..., 1:99, S, 10)
        @test s isa (S === BitSet ? BitSet : Set{Int})
        @test length(s) == 10
        @test rand(s) ∈ 1:99
    end
    for s = (Set([1, 2]), BitSet([1, 2]))
        @test s === rand!(s)
        @test s != Set([1, 2]) # very unlikely
        @test length(s) == 2
        @test s === rand!(s, 3:9) <= Set(3:9)
        @test length(s) == 2
    end
    @test rand(rng..., Pair{Int,Float64}, Set, 3) isa Set{Pair{Int,Float64}}
    @test rand(rng..., Pair{Int,Float64}, Set{Pair}, 3) isa Set{Pair}

    # BitSet
    s = rand(make(BitSet, 1:10, 3))
    @test s isa BitSet
    @test length(s) == 3
    @test s <= Set(1:10)
    @testset "default_sampling(::BitSet) == Int8" begin
        Random.seed!(0)
        rand!(s)
        @test s <= Set(rInt8)
        Random.seed!(0)
        @test s == rand(BitSet, 3)
    end

    # Dict
    for s = (rand(rng..., make(Pair, 1:99, 1:99), Dict, 10),
             rand(rng..., make(Pair, 1:99, 1:99), Dict{Int,Int}, 10))
        @test s isa Dict{Int,Int}
        @test length(s) == 10
        p = rand(s)
        @test p.first ∈ 1:99
        @test p.second ∈ 1:99
    end
    s = Dict(1=>2, 2=>1)
    @test s === rand!(s)
    @test length(s) == 2
    @test first(s).first ∉ (1, 2) # extremely unlikely
    rand!(s, make(Pair, 3:9, Int))
    @test length(s) == 2
    @test first(s).first ∈ 3:9

    d = rand(rng..., Pair{Int,Float64}, Dict, 3)
    @test d isa Dict{Int,Float64}
    dd = rand!(rng..., d, Pair{Int,Int8})
    @test dd === d
    delt = pop!(d)
    @test delt isa Pair{Int,Float64}
    @test delt[2] ∈ rInt8
    @test rand(rng..., Pair{Int,Float64}, Dict{Any,Any}, 3) isa Dict{Any,Any}

    # sparse
    @test rand(rng..., Float64, .5, 10) isa SparseVector{Float64}
    @test rand(rng..., .5, 10) isa SparseVector{Float64}
    @test rand(rng..., Int, .5, 10) isa SparseVector{Int}
    @test rand(rng..., Float64, .5, 10, 3) isa SparseMatrixCSC{Float64}
    @test rand(rng..., .5, 10, 3) isa SparseMatrixCSC{Float64}
    @test rand(rng..., Int, .5, 10, 3) isa SparseMatrixCSC{Int}

    # BitArray
    for S = ([], [Bool], [Bernoulli()])
        @test rand(rng..., S..., BitArray, 10) isa BitVector
        @test rand(rng..., S..., BitVector, 10) isa BitVector
        @test_throws MethodError rand(rng..., S..., BitVector, 10, 20) isa BitVector
        @test rand(rng..., S..., BitArray, 10, 3) isa BitMatrix
        @test rand(rng..., S..., BitMatrix, 10, 3) isa BitMatrix
        @test_throws MethodError rand(rng..., S..., BitVector, 10, 3) isa BitMatrix
    end

    # String
    s = rand(rng..., String)
    @test s isa String
    @test length(s) == 8
    s = rand(rng..., String, 10)
    @test s isa String
    @test length(s) == 10
    s = rand(rng..., "asd", String)
    @test length(s) == 8
    @test Set(s) <= Set("asd")

    # Tuple
    s = rand(rng..., Int, NTuple{3})
    @test s isa NTuple{3,Int}
    s = rand(rng..., 1:3, NTuple{3})
    @test s isa NTuple{3,Int}
    @test all(in(1:3), s)
    s = rand(rng..., 1:3, NTuple{3,Int8})
    @test s isa NTuple{3,Int8}
    @test all(in(1:3), s)

    s = rand(rng..., NTuple{3, Int8})
    @test s isa NTuple{3,Int8}

    s = rand(rng..., Tuple{Int8, UInt8})
    @test s isa Tuple{Int8, UInt8}
    s = rand(rng..., 1:3, Tuple{Int8, UInt8})
    @test s isa Tuple{Int8, UInt8}
    @test all(in(1:3), s)

    s = rand(rng..., 1:3, Tuple, 4)
    @test s isa NTuple{4,Int}
    @test all(in(1:3), s)
    s = rand(rng..., Tuple, 4)
    @test s isa NTuple{4,Float64}

    s = rand(rng..., NTuple{3})
    @test s isa NTuple{3,Float64}

    s = rand(rng..., NTuple{N,UInt8} where N, 3)
    @test s isa NTuple{3,UInt8}
    s = rand(rng..., 1:3, NTuple{N,UInt8} where N, 3)
    @test s isa NTuple{3,UInt8}
    @test all(in(1:3), s)
end

@testset "Rand" for rng in ([], [MersenneTwister(0)], [RandomDevice()])
    for XT = zip(([Int], [1:3], []), (Int, Int, Float64))
        X, T = XT
        r = Rand(rng..., X...)
        @test collect(Iterators.take(r, 10)) isa Vector{T}
        @test r() isa T
        @test r(2, 3) isa Matrix{T}
        @test r(.3, 2, 3) isa SparseMatrixCSC{T}
    end
    for d = (Uniform(1:10), Uniform(Int))
        @test collect(Iterators.take(d, 10)) isa Vector{Int}
    end
end

struct PairDistrib <: RandomExtensions.Distribution{Pair}
end

Random.rand(rng::AbstractRNG, ::Random.SamplerTrivial{PairDistrib}) = 1=>2

@testset "allow abstract Pair when generating a Dict" begin
    d = rand(PairDistrib(), Dict, 1)
    @test d == Dict(1=>2)
    @test typeof(d) == Dict{Any,Any}
end

@testset "some tight typing" begin
    UI = Random.UInt52()
    @test eltype(rand(MersenneTwister(), Random.Sampler(MersenneTwister, UI), .6, 1, 0)) == UInt64
    @test eltype(rand(UI, Set, 3)) == UInt64
    @test eltype(rand(Uniform(UI), 3)) == UInt64
    a = rand(make(Pair, Int, UI))
    @test fieldtype(typeof(a), 2) == UInt64
end

@testset "rand(::Pair)" begin
    @test rand(1=>3) ∈ (1, 3)
    @test rand(1=>2, 3) isa Vector{Int}
    @test rand(1=>'2', 3) isa Vector{Union{Char, Int}}
end

@testset "rand(::AbstractFloat)" begin
    # check that overridden methods still work
    m = MersenneTwister()
    for F in (Float16, Float32, Float64, BigFloat)
        @test rand(F) isa F
        sp = Random.Sampler(MersenneTwister, RandomExtensions.CloseOpen01(F))
        @test rand(m, sp) isa F
        @test 0 <= rand(m, sp) < 1
        F ∈ (Float64, BigFloat) || continue # only types implemented in Random
        sp = Random.Sampler(MersenneTwister, RandomExtensions.CloseOpen12(F))
        @test rand(m, sp) isa F
        @test 1 <= rand(m, sp) < 2
    end
end

@testset "rand(::Type{<:Tuple})" begin
    for types in ([Base.BitInteger_types..., Float16, Float32, Float64, BigFloat, Char, Bool],
                  [Int, UInt64, Char]) # more repetitions
        tlist = rand(types, rand(0:10))
        T = Tuple{tlist...}
        @test rand(T) isa Tuple{tlist...}
    end
    @test rand(Tuple{}) === ()
end

@testset "rand(make(Tuple, ...))" begin
    s = rand([Char, Int, Float64, Bool, 1:3, "abcd", Set([1, 2, 3])], rand(0:10))
    @test rand(make(Tuple, s...)) isa Tuple{Random.gentype.(s)...}
    # explicit test for corner case:
    @test rand(make(Tuple)) == ()
    @test rand(make(Tuple{})) == ()

    t = rand(make(Tuple, 1:3, Char, Int))
    @test t[1] ∈ 1:3
    @test t[2] isa Char
    @test t[3] isa Int && t[3] ∉ 1:3 # extremely unlikely

    t = rand(make(Tuple{Int8,Char,Int128}, 1:3, Char, Int8))
    @test t[1] isa Int8 && t[1] ∈ 1:3
    @test t[2] isa Char
    @test t[3] isa Int128 && t[3] ∈ rInt8
    @test_throws ArgumentError make(Tuple{Int}, 1:3, 1:3)
    @test_throws ArgumentError make(Tuple{Int,Int,Int}, 1:3, 2:4)

    @test rand(make(Tuple, spString, String)) isa Tuple{String,String}

    @test rand(make(Tuple{Int8,Int8})) isa Tuple{Int8,Int8}
    @test rand(make(Tuple{Int8,UInt})) isa Tuple{Int8,UInt}

    # make(Tuple, s, n)
    s = rand(make(Tuple, 1:3, 4))
    @test s isa NTuple{4,Int}
    @test all(in(1:3), s)
    s = rand(make(Tuple, Int8, 4))
    @test s isa NTuple{4,Int8}
    s = rand(make(Tuple, 4))
    @test s isa NTuple{4,Float64}
end

@testset "rand(make(NTuple{N}/Tuple{...}, x))" begin
    s, N = rand([Char, Int, Float64, Bool, 1:3, "abcd", Set([1, 2, 3])]), rand(0:10)
    T = Random.gentype(s)
    rand(make(NTuple{N}, s)) isa NTuple{N,T}
    @test rand(make(NTuple{3}, spString)) isa NTuple{3,String}
    @test rand(make(NTuple{3,UInt8}, 1:3)) isa NTuple{3,UInt8}
    @test rand(make(Tuple{Integer,Integer}, 1:3)) isa Tuple{Int,Int}
    r = rand(make(Tuple{AbstractFloat,AbstractFloat}, 1:3))
    @test r isa Tuple{Float64,Float64}
    @test all(∈(1.0:3.0), r)

    r = rand(make(Tuple{AbstractFloat,Integer}, 1:3))
    @test r isa Tuple{Float64,Int64}
    @test all(in(1:3), r)

    r = rand(make(NTuple{3}))
    @test r isa NTuple{3,Float64}

    r = rand(make(NTuple{N,UInt8} where N, 3))
    @test r isa NTuple{3,UInt8}
    r = rand(make(NTuple{N,UInt8} where N, 1:3, 3))
    @test r isa NTuple{3,UInt8}
    @test all(in(1:3), r)
    r = rand(make(NTuple{N,UInt8} where N, UInt8, 3))
    @test r isa NTuple{3,UInt8}
end

@testset "rand(make(String, ...))" begin
    b = UInt8['0':'9';'A':'Z';'a':'z']

    for (s, c, n) in [(rand(String), b, 8),
                      (rand(make(String, 3)), b, 3),
                      (rand(make(String, "asd")), "asd", 8),
                      (rand(make(String, 3, "asd")), "asd", 3),
                      (rand(make(String, "qwe", 3)), "qwe", 3)]

        @test s ⊆ map(Char, c)
        @test length(s) == n
    end
    @test rand(make(String, Char)) isa String
    @test rand(make(String, 3, Char)) isa String
    @test rand(make(String, Sampler(MersenneTwister, ['a', 'b', 'c']), 10)) isa String
end

@testset "rand(make(Set/BitSet, ...))" begin
    for (S, SS, (low, high)) = ((Set{Int}, Set{Int}, (typemin(Int), typemax(Int))),
                                (Set,      Set,      (0, 1)),
                                (BitSet,   BitSet,   (typemin(Int8), typemax(Int8))))
        for (k, l) = ([1:9] => 1:9, [Int8] => rInt8, [] => ())
            s = rand(make(S, k..., 3))
            @test s isa (SS === Set ? (l == () ? Set{Float64} : Set{eltype(l)}) : SS)
            @test length(s) == 3
            if l == ()
                @test all(x -> low <= x <= high, s)
            else
                @test all(in(l), s)
            end
        end
        rand(make(S, Sampler(MersenneTwister, 1:99), 9)) isa Union{BitSet, Set{Int}}
    end
end

@testset "rand(make(Array/BitArray, ...))" begin
    for (T, Arr) = (Bool => BitArray, Float64 => Array{Float64}),
        k = ([], [T], [Bernoulli(T, 0.3)]),
        (d, dim) = ([(6,)]              => 1,
                    [(2,3)]             => 2,
                    [6]                 => 1,
                    [2, 3]              => 2,
                    [Int8(2), Int16(3)] => 2),
        A = (T == Bool ?
             (BitArray, BitArray{dim}) :
             (Array, Array{Float64}, Array{Float64,dim}, Array{U,dim} where U))

        s = rand(make(A, k..., d...))
        @test s isa  Arr{dim}
        @test length(s) == 6
    end
    @test_throws MethodError make(Matrix, 2)
    @test_throws MethodError make(Vector, 2, 3)
    @test_throws MethodError make(BitMatrix, 2)
    @test_throws MethodError make(BitVector, 2, 3)

    @test rand(make(Array, spString, 9)) isa Array{String}
    @test rand(make(BitArray, Sampler(MersenneTwister, [0, 0, 0, 1]), 9)) isa BitArray
end

@testset "rand(make(Sparse...))" begin
    for k = ([], [Float64], [Bernoulli(Float64, 0.3)]),
        (d, dim) = ([(6,)]              => 1,
                    [(2,3)]             => 2,
                    [6]                 => 1,
                    [2, 3]              => 2,
                    [Int8(2), Int16(3)] => 2)

        s = rand(make(0.3, k..., d...))
        @test s isa (dim == 1 ? SparseVector{Float64,Int} :
                                SparseMatrixCSC{Float64,Int})
        @test length(s) == 6
    end
    @test rand(make(0.3, spString, 9)) isa SparseVector{String}
end
