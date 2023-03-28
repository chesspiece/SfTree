module SfTree

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
Node(dct::Dict{Char,Int}, prnt::Int=0, strt::Int=0, endng::Int=0, id=1, is_leaf=false) = Node(dct, prnt, strt, endng, -1, false, id, is_leaf)


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
    root::Int
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
    sp, sl = first_extension(tree)
    for i in 2:length(str)
        sp, sl = extension_phases(tree, i, sp, sl)
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
    return 2, 1
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
function extension_phases(tree::SuffixTree, phase::Int, str_curr_pos::Int, str_curr_len::Int)
    curr_node = tree.nodes[tree.curr_node]
    sf_node = tree.root
    need_sf = false
    str_break_pos = 1
    walked_len = 1
    first_iteration = true
    for j in tree.current_phase_start:phase
        # On the first iteration we start at the correct tree using correct node and edge from previous extension phase
        if !first_iteration
            # Check if suffix link exists.
            # If not go up a node. We are guranteed to have either of the following:
            #   1) suffix link at the current note
            #   2) suffix link ath the paretnt of the current node
            #   3) root node at the current node or a parent of the current node
            steped_back_count = 0
            if !curr_node.sf_exists && (curr_node.id != tree.root)
                steped_back_count = curr_node.str_id_ending - curr_node.str_id_start + 1
                curr_node = tree.nodes[curr_node.parent]
            end
            if curr_node.id != tree.root
                curr_node = tree.nodes[curr_node.sf_link]
            end

            if curr_node.id == tree.root
                str_curr_pos = j
                str_curr_len = phase + 1 - j
            else
                str_curr_pos = phase - steped_back_count
                str_curr_len = steped_back_count + 1
            end
        end
        first_iteration = false

        flag = 0 # "finish search of the needed position on node"
        while tree.text[str_curr_pos] in keys(curr_node.childrens) && str_curr_len > 1
            curr_node = tree.nodes[curr_node.childrens[tree.text[str_curr_pos]]]

            str_id_start = curr_node.str_id_start
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
                # Rule 3 (inside the edge)
                # Stop current extension if reached
                if tree.text[str_id_start+str_curr_len-1] == tree.text[phase]
                    tree.curr_node = curr_node.parent
                    tree.current_phase_start = j
                    return str_curr_pos, str_curr_len + 1
                end
                # rule 3 end
                walked_len = str_curr_len - 1
                str_break_pos = str_curr_pos + walked_len
                str_curr_len -= walked_len
                flag = 1 # "finish search of the needed position inside the edge"
                break
            end
        end

        if flag == 0 # "finish search of the needed position on node"
            # Rule 1 (on the node)
            if isempty(curr_node.childrens) && curr_node.id != tree.root #rule 1. At most 1 operation
                tree.curr_node = curr_node.id
                continue
            end

            if need_sf
                tree.nodes[sf_node].sf_link = curr_node.id
                tree.nodes[sf_node].sf_exists = true
                need_sf = false
            end
            # Rule 3 (on the node)
            # Stop current extension if reached
            if tree.text[phase] in keys(curr_node.childrens)
                tree.curr_node = curr_node.id
                tree.current_phase_start = j
                return str_curr_pos, str_curr_len + 1
            end

            # Rule 2 (on the node)
            # Create new leaf node
            new_node = Node()
            new_node.str_id_start = str_curr_pos
            new_node.str_id_ending = -1
            new_node.id = tree.nodes_count + 1
            new_node.parent = curr_node.id
            new_node.is_leaf = true
            new_node.childrens = Dict{Char,Int}()
            tree.nodes_count += 1

            # Add node to the tree
            push!(tree.nodes, new_node)
            tree.nodes[curr_node.id].childrens[tree.text[str_curr_pos]] = new_node.id

            # Starting node for suffix link traversal. If syffix link don't exists - go up a node
            tree.curr_node = new_node.id
        else
            # Rule 2 (inside the edge)
            # New non-leaf node
            new_node = Node()
            new_node.str_id_start = curr_node.str_id_start
            new_node.str_id_ending = curr_node.str_id_start + walked_len - 1
            new_node.id = tree.nodes_count + 1
            new_node.parent = curr_node.parent
            new_node.is_leaf = false
            new_node.childrens = Dict{Char,Int}()
            tree.nodes_count += 1

            # New leaf node
            new_node_leaf = Node()
            new_node_leaf.str_id_start = str_break_pos
            new_node_leaf.str_id_ending = -1
            new_node_leaf.id = tree.nodes_count + 1
            new_node_leaf.parent = new_node.id
            new_node_leaf.is_leaf = true
            new_node_leaf.childrens = Dict{Char,Int}()
            tree.nodes_count += 1

            # Edge text modification for current node
            curr_node.str_id_start = new_node.str_id_ending + 1

            push!(tree.nodes, new_node)
            push!(tree.nodes, new_node_leaf)

            # Slice edge
            tree.nodes[curr_node.parent].childrens[tree.text[str_curr_pos]] = new_node.id
            tree.nodes[new_node.id].childrens[tree.text[curr_node.str_id_start]] = curr_node.id
            tree.nodes[new_node.id].childrens[tree.text[new_node_leaf.str_id_start]] = new_node_leaf.id
            curr_node.parent = new_node.id

            if need_sf
                tree.nodes[sf_node].sf_link = new_node.id
                tree.nodes[sf_node].sf_exists = true
            end

            # Creation of the suffix link is needed. Suffix link will be created at the next iteration of current loop 
            need_sf = true
            sf_node = new_node.id

            # Starting node for suffix link traversal. If suffix link don't exists - go up a node
            curr_node = tree.nodes[new_node.id]
            #tree.curr_node = new_node_leaf.id
        end
    end
    tree.current_phase_start = phase
    return str_curr_pos, str_curr_len
end


function get_edges_names(tree::SuffixTree, save_data::Vector{<:AbstractString})
    curr_node = tree.nodes[tree.root]
    for i in values(curr_node.childrens)
        curr_node = tree.nodes[i]
        if curr_node.str_id_ending == -1
            curr_node.str_id_ending = tree.leaf_idx
        end
        push!(save_data, tree.text[curr_node.str_id_start:curr_node.str_id_ending])
        __get_edges_names__(tree, save_data, curr_node)
    end
    return
end


function __get_edges_names__(tree::SuffixTree, save_data::Vector{<:AbstractString}, curr_node)
    for i in values(curr_node.childrens)
        curr_node = tree.nodes[i]
        if curr_node.str_id_ending == -1
            curr_node.str_id_ending = tree.leaf_idx
        end
        push!(save_data, tree.text[curr_node.str_id_start:curr_node.str_id_ending])
        __get_edges_names__(tree, save_data, curr_node)
    end
    return
end

end # module SfTree
