import SfTree: Node, SuffixTree, greet, compare_structs
using Test

@testset "SfTree.jl" begin
    @test greet() == "Hello World!"
end

@testset "Test nodes" begin
    nodes = Vector{Node}([Node(Dict{Char,Int}('a' => 1), -1, -1, -1),
                          Node(Dict{Char,Int}(),          0,  1,  2)])
    nodes2 = Vector{Node}([Node(Dict{Char,Int}('a' => 1), -1, -1, -1),
                          Node(Dict{Char,Int}(),          0,  1,  2)])
    nodes3 = Vector{Node}([Node(Dict{Char,Int}('c' => 1), -1, -1, -1),
                          Node(Dict{Char,Int}(),          0,  3,  2)])
    #tr_expected = SuffixTree{String}(nodes, "A", 0, 0, 0, 2)
    for (n1, n2) in zip(nodes, nodes2)
        @test compare_structs(n1, n2)
    end
    for (n1, n2) in zip(nodes, nodes3)
        @test !compare_structs(n1, n2)
    end
    for (n1, n2) in zip(nodes2, nodes3)
        @test !compare_structs(n1, n2)
    end
end
