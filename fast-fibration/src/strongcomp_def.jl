#=

=#

"""
    Struct to define the properties of a strongly connected component(SCC) object. 
    No arguments is needed to construct this object.

    Properties:
        number_nodes:
            Integer value for the size of the SCC.
        have_input:
            Boolean value to signal whether the SCC has input from other SCC.
        nodes:
            Array of integers regarding the indexes of the nodes belonging
            to the fiber.
        type:
            Integer value ranging from 0 to 2. Each value correspond to a different
            type of SCC. This classify is related to the inputs that the SCC receives
            and it is used for a proper initialization of the fibration partitioning
            algorithm.
"""
mutable struct StrongComponent
    number_nodes::Int
    have_input::Bool
    nodes::Array{Int}
    type::Int
    function StrongComponent()
        number_nodes = 0
        have_input = false
        nodes = Int[]
        type = -1
        new(number_nodes, have_input, nodes, type)
    end
end

"""
    Add 'node' to 'strong' object. If 'node' is an array
    of nodes, then all nodes are inserted.
"""
function insert_nodes(node::Int, strong::StrongComponent)
    strong.number_nodes += 1
    append!(strong.nodes, [node])
end

function insert_nodes(node::Array{Int}, strong::StrongComponent)
    strong.number_nodes += length(node)
    append!(strong.nodes, node)
end

function get_nodes(strong::StrongComponent)
    return strong.nodes
end

function get_input_bool(strong::StrongComponent)
    return strong.have_input
end

"""
    Check if the given SCC receives or not input from another 
    components in the 'graph'.

    the field 'have_input' of 'strong' is modified to 'true'
    if the component receives external information. Otherwise,
    'have_input' maintains its default ('false').
"""
function check_input(strong::StrongComponent, graph::Graph)
    from_out = false
    for u in strong.nodes
        input_nodes = get_in_neighbors(u, graph)
        for w in input_nodes
            if w in strong.nodes
                from_out = false
            else
                from_out = true
            end
            if from_out
                strong.have_input = true
                break
            end
        end
        if strong.have_input
            break
        end
    end
    return
end

"""
    This function should be called after 'check_input'
"""
function classify_strong(strong::StrongComponent, graph::Graph)
    if strong.have_input
        strong.type = 0
    else
        """
            If it doesn't receive any external input, then we
            must check if it is an isolated self-loop node.
        """
        if length(strong.nodes)==1
            in_neighbors = get_in_neighbors(strong.nodes[1], graph)
            if length(in_neighbors)==0
                strong.type = 1
            else
                strong.type = 2 # Isolated self-loop node.
            end
        else
            strong.type = 1 # SCC does not have external input.
        end
    end
    return
end