# =================== BALANCED COLORING ===================== #

"""
    Initialization function for the minimal balancing coloring. Differently
    from the fast fibration algorithm, the isolated self-loop nodes can be put
    in different classes already in the initial partition.
"""
function initialize_coloring(graph::Graph)
    N = length(graph.vertices)

    #scc_info = find_strong(graph)
    scc_info = extract_strong(graph, true)
    node_labels = scc_info[1]
    unique_labels = scc_info[2]
    components = scc_info[3]

    # -- 'sccs' holds a list of 'StrongComponent' objects --
    sccs = StrongComponent[]
    for label in collect(keys(components))
        new_scc = StrongComponent()
        insert_nodes(components[label], new_scc)
        push!(sccs, new_scc)
    end

    # -- Check if each SCC receives or not input from other
    # -- components not itself --
    partition = Fiber[Fiber()]
    autopivot = Fiber[]
    for strong in sccs
        check_input(strong, graph)
        classify_strong(strong, graph)

        if strong.type == 0
            insert_nodes(strong.nodes, partition[1])
        else strong.type == 1 
            new_fiber = Fiber()
            insert_nodes(strong.nodes, new_fiber)
            append!(partition, [new_fiber])
        end
    end

    # -- Define the pivot set queue and fiber pointer for each
    # -- node. Also push the defined classes to the queue.
    fiber_index = [ -1 for j in 1:N ]
    for (index, class) in enumerate(partition)
        for v in class.nodes
            fiber_index[v] = index
        end
        partition[index].index = index
    end
    # -- Save the graph property 'fiber_index' --
    set_vertices_properties("fiber_index", fiber_index, graph)
    return partition, autopivot
end

"""
    Splitting function for the minimal balanced coloring algorithm.

    Given 'graph' with the vertex property 'fiber_index' indicating
    the class of each node, and also the 'ncolor' and 'ntype' corresponding
    to the current number of colors and the number of edge types in the 
    network, the function modifies 'fiber_index' if the coloring is not
    balanced and returns the new value of 'ncolor'.
"""
function s_coloring(graph::Graph, ncolor::Int, ntype::Int)
    fiber_index = graph.int_vproperties["fiber_index"]
    edgetype_prop = graph.int_eproperties["edgetype"]

    # -- Set the ISCV matrix --
    input_dict = Dict{String, Array{Int}}()
    iscv = zeros(Int, (ncolor*ntype, length(graph.vertices)))
    # For each node check its incoming edges' colors. 
    for v in 1:length(graph.vertices)
        node = graph.vertices[v]
        incoming_edges = node.edges_target
        for edge in incoming_edges
            src = edge.source
            incoming_color = fiber_index[src]
            incoming_type = edgetype_prop[edge.index]
            # pay attention on indexing.
            iscv[(incoming_color-1)*ntype + incoming_type, v] += 1
        end
        # -- Convert the ISCV into a string --
        input_str = ""
        for j in 1:(ncolor*ntype)
            input_str*="$(iscv[j,v])"
        end
        # -- Put nodes with same ISCV in the same key.
        if get(input_dict, input_str, -1)==-1
            input_dict[input_str] = Int[]
        end
        push!(input_dict[input_str], v)
    end

    # -- The keys of 'input_dict' are the unique ISCV 
    # -- and each of these keys holds the belonging nodes.
    # -- NOTE: nodes without input are in the same key.
    updated_colors = collect(keys(input_dict))
    increase_color = Dict{Int,Bool}()
    for f_index in fiber_index
        increase_color[f_index] = false
    end
    for color in updated_colors
        unique = collect(Set([fiber_index[v] for v in input_dict[color]]))
        # If the nodes come from two different class, then it is an 
        # improper splitting
        if length(unique)>1
            continue
        end

        if increase_color[unique[1]]
            ncolor += 1
            # -- assign new color to this new class --
            for v in input_dict[color]
                fiber_index[v] = ncolor
            end
        else
            increase_color[unique[1]] = true
        end
    end
    return ncolor
end

"""
    Main call function for the minimal balanced coloring.

    'graph' is the network structure to be partitioned, and 'eprop_name'
    is the name of the edge property holding the type of the edges. (this
    property must be an integer prop ranging from 1 to number of types.)
"""
function minimal_coloring(graph::Graph, eprop_name="edgetype")
    if !graph.is_directed
        print("Undirected network\n")
        return
    end

    edgetype_prop = graph.int_eproperties[eprop_name]
    num_edgetype = length(collect(Int, Set(edgetype_prop)))
 
    # -- Set the 'fiber_index' property for the network --
    partition, autopivot = initialize_coloring(graph)
    fiber_index = graph.int_vproperties["fiber_index"]
    # -- Number of color before and after refinement --
    ncolor_new = -1
    #ncolor_old = length(collect(Int, Set(fiber_index)))
    ncolor_old = maximum(fiber_index)
    # -- Refinement process through coloring --
    while true
        ncolor_new = s_coloring(graph, ncolor_old, num_edgetype)
        if ncolor_new==ncolor_old
            break
        end
        #print("$(ncolor_old), $(ncolor_new)\n")
        ncolor_old = ncolor_new
    end
    # --------------------------------------------------------- #

    # -- After the coloring is balanced generate the fiber structure --
    fiber_dict = Dict{Int, Array{Int}}()
    fiber_index = graph.int_vproperties["fiber_index"]
    for v in 1:length(graph.vertices)
        if get(fiber_dict, fiber_index[v], -1)==-1
            fiber_dict[fiber_index[v]] = Int[]
        end
        push!(fiber_dict[fiber_index[v]], v)
    end

    partition = Fiber[]
    for key in collect(keys(fiber_dict))
        new_fiber = Fiber()
        insert_nodes(fiber_dict[key], new_fiber)
        new_fiber.index = length(partition)+1
        push!(partition, new_fiber)
    end
    return partition
end