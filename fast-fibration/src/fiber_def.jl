#=
    Define 'Fiber' object and its main methods.

    Define 'StrongComponent' object and its main methods.
=#


"""
    Struct to define the properties of a fiber object. No arguments is
    needed to construct this object.

    Properties:
        index:
            Integer value to store its index during the algorithms.
        number_nodes:
            Integer value for the size of the fiber.
        number_regulators:
            Integer value for the number of fiber regulators.
        regulators:
            Array of integers regarding the indexes of the regulators of
            the fiber.
        nodes:
            Array of integers regarding the indexes of the nodes belonging
            to the fiber.
        input_type:
            Dictionary where keys is a type of input{Int} and the value is an
            integer corresponding to the number of this type of input that the
            fiber receives. 
"""
mutable struct Fiber
    index::Int
    number_nodes::Int
    number_regulators::Int
    regulators::Array{Int}
    nodes::Array{Int}
    input_type::Dict{Int, Int}
    function Fiber()
        index = 0
        number_nodes = 0
        number_regulators = 0
        regulators = Int[]
        nodes = Int[]
        input_type = Dict{Int, Int}()
        new(index, number_nodes, number_regulators, 
            regulators, nodes, input_type)
    end
end

function insert_nodes(nodelst::Int, fiber::Fiber)
    fiber.number_nodes += 1
    append!(fiber.nodes, [nodelst])
end

function insert_nodes(nodelst::Array{Int}, fiber::Fiber)
    append!(fiber.nodes, nodelst)
    fiber.number_nodes = length(fiber.nodes)
end

function delete_nodes(nodelist::Array{Int}, fiber::Fiber)
    fiber.nodes = [ node for node in fiber.nodes if !(node in nodelist)]
    fiber.number_nodes = length(fiber.nodes)
end

function insert_regulator(reg::Int, fiber::Fiber)
    append!(fiber.regulators, [reg])
    fiber.number_regulators += 1
end

function get_nodes(fiber::Fiber)
    return fiber.nodes
end

function num_nodes(fiber::Fiber)
    return fiber.number_nodes
end

# change docs
"""
    Returns all nodes in 'graph' that is pointed by 'fiber'.
    This function is important to define an efficient procedure
    to determine which fibers are input-set unstable with 
    respect to 'fiber', assuring a time complexity of the order
    of the outgoing neighborhood of 'fiber'.
"""
function sucessor_nodes(graph::Graph, fiber::Fiber)
    sucessor = Int[]
    for node in fiber.nodes
        out_neigh = get_out_neighbors(node, graph)
        append!(successor, out_neigh)
    end
    return collect(Int, Set(sucessor))
end

# change docs
"""
   Given the two fiber objects 'fiber' and 'pivot', it checks if 'fiber'
   is input-set stable with respect to 'pivot', that is, every node of
   'fiber' receives equivalent information, through 'graph', from 'pivot'.

   if input-set stable, returns true. Otherwise, returns false.

    *** MISMATCH IN THE PYTHON CODE - CHECK LATER.
"""
function input_stability(fiber::Fiber, pivot::Fiber, graph::Graph, num_edgetype::Int)
    fiber_nodes = get_nodes(fiber)
    pivot_nodes = get_nodes(pivot)
    edges_received = Dict{Int,Array{Int}}()

    edgelist = graph.edges
    edgetype = graph.int_eproperties["edgetype"]

    # -- initiate the input-set array for each node of 'fiber' --
    for node in fiber_nodes
        edges_received[node] = zeros(Int, num_edgetype)
    end

    # -- Based on the outcoming edges of 'pivot' set, we set the
    # -- input-set of each node of 'fiber'.
    for w in pivot_nodes
        pivot_obj = graph.vertices[w]
        out_edges = pivot_obj.edges_source
        for out_edge in out_edges
            edge_index = out_edge.index
            target_node = out_edge.target
            if get(edges_received, target_node, -1)!=-1
                edges_received[target_node][edge_index] += 1
            end
        end
    end

    # -- Check input-set stability --
    for j in 1:length(fiber_nodes)-1
        if edges_received[fiber_nodes[j]]!=edges_received[fiber_nodes[j+1]]
            return false
        end
    end
    return true
end

function copy_fiber(fiber::Fiber)
    copy_fiber = Fiber()
    copy_fiber.index = fiber.index
    copy_fiber.nodes = copy(fiber.nodes)
    copy_fiber.input_type = copy(fiber.input_type)
    copy_fiber.number_nodes = length(copy_fiber.nodes)
    copy_fiber.number_regulators = fiber.number_regulators
    copy_fiber.regulators = copy(fiber.regulators)
    return copy_fiber
end
