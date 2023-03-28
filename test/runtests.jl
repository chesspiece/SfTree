import SfTree: SuffixTree, build_sf_tree, Node, compare_structs, get_edges_names
using Test

@testset "Test nodes" begin
    nodes = Vector{Node}([Node(Dict{Char,Int}('a' => 1), -1, -1, -1),
                          Node(Dict{Char,Int}(),          0,  1,  2)])
    nodes2 = Vector{Node}([Node(Dict{Char,Int}('a' => 1), -1, -1, -1),
                          Node(Dict{Char,Int}(),          0,  1,  2)])
    nodes3 = Vector{Node}([Node(Dict{Char,Int}('c' => 1), -1, -1, -1),
                          Node(Dict{Char,Int}(),          0,  3,  2)])
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


@testset "Build large tree without exception" begin
    data = "ATCTACCAGCAGTGAACATGGGAGGACCAGT" *
           "AAGGAAGGCTTACCCTCGATGTGTTACAGAC" *
           "TCGTTCGTAGGGTGTATAACGCCGCCGCTGG\$"
    @test try build_sf_tree(data)
        true
    catch
        false
    end

    data = "ACCGACCTGAGATACGCCCGTAATTAAAACTTTT" *
           "CTTAACAGACTGTTACTACATCCATGTGTCACAC" *
           "GGCAGGTTGTGAGGGGTTGTTGAGTCATACATGG" *
           "TCCGCGGATATGTATGAGCTGGGACCGTTCAATA" *
           "TGACAGGCTACTTTTCGAAACCGCAGGAGAAGCA" *
           "ATTGAGAGGTCCAACCACACCCCCGTCCAGATCC" *
           "CACCGTCAAGATGGAAGCTATACCGTTACCACTA" *
           "CACGCATGTCACGTCGGCTGCAACCGCTTGGGCC" *
           "TTGCGGTATAAAGATCGCTTCGCTACTACACCCT" *
           "CAACAACTCGATGCTCACTCAGCTCAAGTAACCG" *
           "TACCCAATCGACTGAGTGCCCCCGTACAGTATCA" *
           "ACGAATTGGAGCTAACCGCTCTTAAGGCTTTGAA" *
           "ATAGCTCGCTACCTGGACCGATAGCTTGATTAAT" *
           "TCTACTGTGGGAATCGCCGGTGGCTAGACGACTT" *
           "CCGTCTAGCTCCGTGAATCCAACCAAATACTACG" *
           "ACCGACTTCGATAGAGTTAAAGAATAACGAGACG" *
           "CAGGTATAGAAAATATTACATCATATGCTACACT" *
           "TAAACGGATGCGTTGCTTCTGGCTTATTAAGACA" *
           "GGGGCCTCATGGTCCCTCTGAGGGGCAAGGAAGC" *
           "GCGACGGCGAGGCTCGCTGTGATACGCAAACATG" *
           "ATTGGAACCGTATTATTTCGATAGTCTTTTGCAA" *
           "CCTGTCCCAGAAGGTATGCATCGTGCCGCGTTTT" *
           "GCCACGCGGGCGTGACATTGCTCCGCAAATTATT" *
           "ACAAGGATCACCTGGCAGCAAGCGCTACCCTTAG" *
           "AATGTGCTCGTCCGGCATTATGTCCGTGAACTGC" *
           "GACTCAT\$"

    @test try build_sf_tree(data)
        true
    catch
        false
    end
end


@testset "Test that build tree have correct edges" begin
    text = "ATAAATG\$"
    tree = build_sf_tree(text)
    tree_edges = Vector{String}()
    get_edges_names(tree, tree_edges)
    test_labels = ["AAATG\$", "G\$", "T", "ATG\$", "TG\$", "A", "A", "AAATG\$", "G\$", "T", "G\$", "\$"]

    for label in test_labels
        @test label in tree_edges
    end
    @test length(test_labels) == length(tree_edges)
end
