module SfTree
export greet

greet() = return "Hello World!"

mutable struct Node
    childrens::Dict{Char,Int}
    parent::Int
    str_id_start::Int
    str_id_ending::Int
    sf_link::Int
    sf_exists::Bool
    id::Int
    is_leaf::Bool
    #smallest_leaf_num::Int #index of smallest leaf node in subtree of this node
end
Node(prnt::Int=0, strt::Int=0, endng::Int=0, id=1, is_leaf=false) = Node(Dict{Char,Int}(), prnt, strt, endng, -1, false, id, is_leaf)
Node(dct::Dict{Char,Int}, prnt::Int = 0, strt::Int = 0, endng::Int = 0, id=1, is_leaf=false) = Node(dct, prnt, strt, endng, -1, false, id, is_leaf)

"""
    compare_structs(a::T, b::T) where {T}

Check if structure a and b of the ame type have the same values
Structs should not contain mutable strcts as variables
"""
function compare_structs(a::T, b::T) where {T}
    f = fieldnames(T)
    getfield.(Ref(a), f) == getfield.(Ref(b), f)
end

mutable struct SuffixTree{T<:AbstractString}
    #=
    sf_ - means that this variable is needed for suffix links construction
    0 - is the index of root
    =#
    nodes::Vector{Node}
    nodes_count::Int
    text::T
    term::Char
    #sf_curr_full_str::Int
    #sf_prev_node::Int
    #leaf_val_end::Int
    root::Int
    #phase_id::Int
    curr_node::Int
    current_phase_start::Int
    leaf_idx::Int
end
SuffixTree(str::AbstractString) = SuffixTree(Vector{Node}([Node()]), 1, str, '$', 1, 2, 1, 1)
SuffixTree(str::AbstractString, term::Char) = SuffixTree(Vector{Node}(), 1, str, term, 1, 2, 1, 1)


"""
    build_sf_tree(str::AbstractString)::SuffixTree

TBW
"""
function build_sf_tree(str::AbstractString)::SuffixTree
    tree = SuffixTree(str)
    first_extension(tree)
    for i in 2:length(str)
        extension_phases(tree, i)
        tree.leaf_idx += 1
    end
    return tree
end


"""
    first_extension(tree::SuffixTree)

TBW
"""
function first_extension(tree::SuffixTree)
    new_node = Node()
    #new_node.sf_exists = false
    #new_node.sf_link = -1
    new_node.str_id_start = 1
    new_node.str_id_ending = -1
    new_node.id = tree.nodes_count + 1
    new_node.parent = 1
    new_node.is_leaf = true
    new_node.childrens = Dict{Char,Int}()
    tree.nodes_count += 1
    push!(tree.nodes, new_node)
    tree.nodes[1].childrens[tree.text[1]] = 2
    tree.current_phase_start = 1
    tree.curr_node = 2
    return
end


"""
    extension_phases(tree::SuffixTree, phase::Int)
    Ukonnen's suffix tree construction extenson phases for phase phase(i+1 in Gusfield book)

    Inputs:
    -------
        tree - implicit suffix tree i.
        phase - previous phase number
    Outputs:
    --------
        Implicit suffix tree phase(i+1 in Gusfield book)
"""
function extension_phases(tree::SuffixTree, phase::Int)
    curr_node = tree.nodes[tree.curr_node]
    sf_node = tree.root
    need_sf = false
    for j in tree.current_phase_start:phase
        #str_curr_pos = phase
        #str_curr_len = 0
        # Check if suffix link exists.
        # If not go up a node because we a guranteed to either have node with suffix link
        # or root node at the current node or at the paret of root node.
        if !curr_node.sf_exists && (curr_node.id != tree.root)
            curr_node = tree.nodes[curr_node.parent]
        end
        if curr_node.id != tree.root
            curr_node = tree.nodes[curr_node.sf_link]
        end

        if curr_node.str_id_ending == -1
            str_id_ending = tree.leaf_idx
        else
            str_id_ending = curr_node.str_id_ending
        end
        if curr_node.id == tree.root
            str_curr_pos = j
        else
            str_curr_pos = curr_node.str_id_ending + 1
        end
        str_curr_len = phase + 1 - str_curr_pos

        flag = 0 # "finish_on_node"
        while tree.text[str_curr_pos] in keys(curr_node.childrens) && str_curr_len > 1
            curr_node = tree.nodes[curr_node.childrens[tree.text[str_curr_pos]]]

            str_id_start = curr_node.str_id_start # need to check that it less than j?
            if curr_node.str_id_ending == -1
                str_id_ending = tree.leaf_idx
            else
                str_id_ending = curr_node.str_id_ending
            end

            walked_len = str_id_ending - str_id_start + 1
            if walked_len < str_curr_len
                str_curr_pos += walked_len 
                str_curr_len -= walked_len
            else
                # rule 3
                if tree.text[str_id_start + str_curr_len - 1] == tree.text[phase]
                    tree.current_phase_start = j - 1
                    return tree
                end
                # erule 3 end
                walked_len = str_curr_len - 1
                str_curr_pos += walked_len 
                str_curr_len -= walked_len
                flag = 1 # "finish_inside_edge"
                break
            end
        end

        if flag == 0
            # rule 1
            if isempty(curr_node.childrens) #rule 1. At most 1 operation
                continue
            end

            # rule 3
            if tree.text[phase] in keys(curr_node.childrens)
                tree.current_phase_start = j - 1
                return tree
            end

            #rule 2
            new_node = Node()
            #new_node.sf_exists = false
            #new_node.sf_link = -1
            new_node.str_id_start = str_curr_pos
            new_node.str_id_ending = -1
            new_node.id = tree.nodes_count + 1
            new_node.parent = curr_node.id
            new_node.is_leaf = true
            new_node.childrens = Dict{Char,Int}()
            tree.nodes_count += 1
            push!(tree.nodes, new_node)
            tree.nodes[curr_node.id].childrens[tree.text[str_curr_pos]] = new_node.id
            tree.curr_node = curr_node.id
            need_sf = false
        else
            # need additions
            new_node = Node()
            new_node.str_id_start = str_curr_pos
            new_node.str_id_ending = 100
            new_node.id = tree.nodes_count + 1
            new_node.parent = curr_node.id
            new_node.is_leaf = false
            new_node.childrens = Dict{Char,Int}()
            tree.nodes_count += 1

            push!(tree.nodes, new_node)
            tree.nodes[curr_node.id].childrens[tree.text[str_curr_pos]] = new_node.id
            tree.curr_node = curr_node.id
            need_sf = false
            sf_node = curr_node.id

            # slice edge
            curr_node = tree.nodes[curr_node.parent]
            #curr_node_p.childrens[tree.text[str_curr_pos]] = new_node.id
        end
        if need_sf
            tree.nodes[sf_node].sf_link = new_node.id
        end
    end
    tree.current_phase_start = phase - 1
    return 
end

end # module SfTree
