#=

=#

"""
    Returns an array containing the degree for each vertex
    in the given graph.

    Args:
        graph:
            'Graph' structure where the vertices and edges are placed.
        mode:
            {'total', 'in', 'out'} string to signal which type of
            degree to return.
    Return:
        degree:
            Integer representing the value of the degree.
"""
function get_degree(graph::Graph, mode::String)
    degree = zeros(Int, length(graph.vertices))
    for j in 1:length(graph.vertices)
        vertex = graph.vertices[j]
        if mode=="total"
            degree[j] = length(vertex.edges_source) + length(vertex.edges_target)
        elseif mode=="in"
            degree[j] = length(vertex.edges_target)
        elseif mode=="out"
            degree[j] = length(vertex.edges_source)
        end
    end
    return degree
end

"""
    Returns an array containing the indexes of each incoming 
    neighbor of 'node' in 'graph'.

    Args:
        node:
            Integer representing the index of the node in the
            parsed graph for which we want to extract the neighbors.
        graph:
            'Graph' structure where the vertices and edges are placed.
    Return:
        rtn_neighbors:
            Array of integers representing all the indexes of the incoming 
            neighbors.
"""
function get_in_neighbors(node::Int, graph::Graph)
    node_obj = graph.vertices[node]

    # -- edges where 'node' is the target --
    incoming_edges = node_obj.edges_target
    incoming_neighbors = Int[]
    for edge in incoming_edges
        # fundamental check
        if edge.target!=node
            print("BUG. aborted.\n")
            return
        end
        push!(incoming_neighbors, edge.source)
    end
    rtn_neighbors = collect(Set(incoming_neighbors))
    return rtn_neighbors
end

"""
    Returns an array containing the indexes of each outgoing 
    neighbor of 'node' in 'graph'.

    Args:
        node:
            Integer representing the index of the node in the
            parsed graph for which we want to extract the neighbors.
        graph:
            'Graph' structure where the vertices and edges are placed.
    Return:
        rtn_neighbors:
            Array of integers representing all the indexes of the outgoing 
            neighbors.
"""
function get_out_neighbors(node::Int, graph::Graph)
    node_obj = graph.vertices[node]

    # -- edges where 'node' is the source --
    outgoing_edges = node_obj.edges_source
    outgoing_neighbors = Int[]
    for edge in outgoing_edges
        # fundamental check
        if edge.source!=node
            print("BUG. aborted.\n")
        end
        push!(outgoing_neighbors, edge.target)
    end
    rtn_neighbors = collect(Set(outgoing_neighbors))
    return rtn_neighbors
end

"""
    Returns an array containing the indexes of each neighbor (in and out) 
    of 'node' in 'graph'.

    Args:
        node:
            Integer representing the index of the node in the
            parsed graph for which we want to extract the neighbors.
        graph:
            'Graph' structure where the vertices and edges are placed.
    Return:
        rtn_neighbors:
            Array of integers representing all indexes of all neighbors. 
"""
function get_all_neighbors(node::Int, graph::Graph)
    incoming_neighbors = get_in_neighbors(node, graph)
    outcoming_neighbors = get_out_neighbors(node, graph)

    neighbors = Int[]
    append!(neighbors, incoming_neighbors)
    append!(neighbors, outcoming_neighbors)
    rtn_neighbors = collect(Set(neighbors))
    return rtn_neighbors
end

"""
    Breadth-first search from 'source' in 'graph'. Returns three arrays:
    'color', 'dist' and 'parent'.

    Args:
        source:
            Integer index of the source node of the BFS algorithm.
        graph:
            'Graph' structure where the vertices and edges are placed.
    Return:
        color:
            visited status of the node (1=visited)
        dist:
            shortest distance between 'source' and the current node.
        parent:
            parent of each node in the tree from 'source'.
"""
function bfs_search(source::Int, graph::Graph)
    N = length(graph.vertices)
    color = [-1 for j in 1:N]
    dist = [-1 for j in 1:N]
    parent = [-1 for j in 1:N]

    # -1/0/1 -> white/gray/black
    color[source] = 0
    dist[source] = 0
    parent[source] = -1

    queue = Int[]
    push!(queue, source)
    while length(queue)>0
        u = pop!(queue)
        u_adj = get_out_neighbors(u, graph)
        for w in u_adj
            if color[w]==-1
                color[w] = 0
                dist[w] = dist[u]+1
                parent[w] = u
                push!(queue, w)
            end
        end
        color[u] = 1
    end
    return color, dist, parent
end

function dfs_search(graph::Graph)
    N = length(graph.vertices)
    color = [-1 for j in 1:N ]
    dist = [-1 for j in 1:N ]
    parent = [-1 for j in 1:N ]
    finished = [-1 for j in 1:N ]

    time = [0]
    for u in 1:N
        if color[u]==-1
            dfs_visit(u, graph, time, color, dist, parent, finished)
        end
    end
    return color, parent, finished
end

"""
    Invert the direction of all edges of 'graph'.
"""
function transpose_graph(graph::Graph)
    edges = graph.edges
    for edge in edges
        src = edge.source
        tgt = edge.target
        edge.source = tgt
        edge.target = src
    end
    for node in graph.vertices
        aux_src = node.edges_source
        aux_tgt = node.edges_target
        node.edges_source = aux_tgt
        node.edges_target = aux_src
    end
end

function get_root(node::Int, parent::Array{Int,1})
    r = node
    while parent[r]!=-1
        r = parent[r]
    end
    return r
end

function dfs_visit(u::Int, graph::Graph, time::Array{Int},
                   color::Array{Int}, dist::Array{Int},
                   parent::Array{Int}, finished::Array{Int})
    time[1] += 1
    dist[u] = time[1]
    color[u] = 0
    u_adj = get_out_neighbors(u, graph)
    for v in u_adj
        if color[v]==-1
            parent[v] = u
            dfs_visit(v, graph, time, color, dist, parent, finished)
        end
    end
    color[u] = 1
    time[1] += 1
    finished[u] = time[1]
end

"""
    Extract the partition of strongly connected components of the graph.
    Obtained using the Kosajaru algorithm.

    Args:
        graph:
            'Graph' structure where the vertices and edges are placed.
        return_dict:
            {default=false} to signal whether the function should return
            a formatted dictionary where keys are root nodes of components
            and values are arrays containing the nodes belonging to this
            strongly connected component.
    Return:
        node_labels:
            Array of integers with length equal to the total number of nodes.
            The jth index of this array represent the index of the SCC in which
            the node j belongs to.
        unique_labels:
            Array containing all the unique labels for each SCC found.
        scc_trees(return_dict=true):
            Dictionary where keys are SCC labels and values are arrays containing
            all the nodes belonging to the current SCC label.

"""
function extract_strong(graph::Graph, return_dict=false)
    N = graph.N
    color, parent, finished = dfs_search(graph)

    # Create the tranpose graph from 'graph'.
    graph_t = copy_graph(graph)
    transpose_graph(graph_t)

    time = [0]
    color_t = [-1 for j in 1:N ]
    dist_t = [-1 for j in 1:N ]
    parent_t = [-1 for j in 1:N ]
    finished_t = [-1 for j in 1:N ]
    # Apply second DFS to 'graph_t' in decreasing order of 'finished'.
    node_ordering = sortperm(finished, rev=true)
    for u in node_ordering
        if color_t[u]==-1
            dfs_visit(u, graph_t, time, color_t, dist_t, parent_t, finished_t)
        end
    end

    # Now, each DFS tree in 'parent_t' represents an strongly connected component.
    scc_trees = Dict{Int, Array{Int}}()
    node_labels = [-1 for j in 1:N]
    for u in 1:N
        root = get_root(u, parent_t)
        if get(scc_trees, root, -1)==-1
            scc_trees[root] = Int[]
        end
        push!(scc_trees[root], u)
        node_labels[u] = root
    end
    unique_labels = collect(Int, Set(node_labels))
    if return_dict
        return node_labels, unique_labels, scc_trees
    end
    return node_labels, unique_labels
end