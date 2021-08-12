#=
    Code for interacting with a Graph structure by:
        - Adding nodes
        - Adding edges
        - Checking if a given edge exists
        - Retrieving neighbors of a given node.
        - Getting formatted edgelist of graph.
        - Creating a copy of a graph.
=#

"""
    Create a new Vertex in the given Graph.
    
    Args:
        graph:
            'Graph' structure for which we want to add a node.
"""
function add_node(graph::Graph)
    index = graph.N+1
    new_node = Vertex(index)
    push!(graph.vertices, new_node)
    graph.N += 1
end

"""
    Create an edge between vertex 'src' and vertex 'tgt'.
    Edges are created as directed edges (src->tgt) whether
    the network is directed or not. 

    The direction of the network defines the behavior of
    other functions.

    Args:
        src:
            Source vertex of the created edge.
        tgt:
            Target vertex of the created edge.
        graph:
            'Graph' structure where the vertices and edges are placed.
"""
function add_edge(src, tgt, graph::Graph)
    is_directed = graph.is_directed
    node_i = graph.vertices[src]
    node_j = graph.vertices[tgt]

    # -- Create the edge object --
    new_edge = Edge(node_i.index, node_j.index)
    push!(node_i.edges_source, new_edge)
    push!(node_j.edges_target, new_edge)
    push!(graph.edges, new_edge)
    new_edge.index = length(graph.edges)
    graph.M += 1
end

"""
    Check if the edge(src,tgt) already exists in the network.
    If the network is directed, then we check for src->tgt, while
    for the undirected, src<->tgt.

    Args:
        src:
            Source vertex of the searched edge.
        tgt:
            Target vertex of the searched edge.
        graph:
        'Graph' structure where the vertices and edges are placed.
"""
function is_edge(src, tgt, graph::Graph)
    node_i = graph.vertices[src]
    node_j = graph.vertices[tgt]
    is_directed = graph.is_directed

    if is_directed
        out_edges = node_i.edges_source
        for cur_edge in out_edges
            if cur_edge.target == node_j.index
                return true
            end
        end
    else
        out_edges = node_i.edges_source
        in_edges = node_i.edges_target
        for cur_edge in out_edges
            if cur_edge.target == node_j.index
                return true
            end
        end
        for cur_edge in in_edges
            if cur_edge.source == node_j.index
                return true
            end
        end
    end
    return false
end

"""
    If the network is directed, returns outcoming neighbors.
    Otherwise, returns all neighbors.

    Args:
        v_index:
            Vertex for which we want to retrieve the neighbors.
        graph:
            'Graph' structure where the vertices and edges are placed.
"""
function get_all_neighbors_aware(v_index::Int, graph::Graph)
    node_v = graph.vertices[v_index]
    neighbors = Int[]
    out_edges_v = node_v.edges_source
    for cur_edge in out_edges_v
        append!(neighbors, [cur_edge.target])
    end
    if graph.is_directed
        return collect(Int, Set(neighbors))
    end
    in_edges_v = node_v.edges_target
    for cur_edge in in_edges_v
        append!(neighbors, [cur_edge.source])
    end
    return collect(Int, Set(neighbors))
end

# -----> COPY FUNCTIONS FOR GRAPH <----- #

"""
    Returns a (M,2) matrix representing the edgelist of the 
    parsed 'graph'.

    Args:
        graph:
            'Graph' structure where the vertices and edges are placed.
"""
function get_edgelist(graph::Graph)
    M = graph.M
    edgelist = zeros(Int, (M,2))
    for (j, edge) in enumerate(graph.edges)
        edgelist[j,1] = edge.source
        edgelist[j,2] = edge.target
    end
    return edgelist
end

function copy_graph(graph::Graph)
    edges = get_edgelist(graph)
    new_graph = graph_from_edgelist(edges, graph.is_directed)

    new_graph.int_vproperties = copy(graph.int_vproperties)
    new_graph.float_vproperties = copy(graph.float_vproperties)
    new_graph.string_vproperties = copy(graph.string_vproperties)
    new_graph.int_eproperties = copy(graph.int_eproperties)
    new_graph.float_eproperties = copy(graph.float_eproperties)
    new_graph.string_eproperties = copy(graph.string_eproperties)
    return new_graph
end