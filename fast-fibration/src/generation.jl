#=
    Network generation.
=#

"""
    Returns an Erdos-Renyi random graph according to the G(N, p) model.

    Args:
        N:
            Total number of nodes of the graph.
        p:
            Probability of existence between pair of nodes.
        is_directed:
            Boolean to signal whether the final graph is undirected or 
            directed.
        self:
            {default=false} Boolean to signal whether self-loops are allowed.
    Return:
        graph:
            'Graph' structure representing the final graph according to G(N,p).
"""
function erdos_renyi_net(N::Int, p::Float64, is_directed::Bool, self=false)
    if p<=0 || p>=1
        return
    end

    graph = Graph(is_directed)
    for i in 1:N
        add_node(graph)
    end

    w = -1
    lp = log(1.0-p)

    if is_directed # ----- directed -----
        v = 0
        while v < N
            mu = rand(1)[1]
            lr =  log(1.0 - mu)
            w += (1 +  floor(Int, lr/lp))
            while v<N && N<=w
                w -= N
                v += 1
            end
            if v < N
                if v==w && self
                    add_edge(v+1, w+1, graph)
                elseif v!=w
                    add_edge(v+1, w+1, graph)
                end
            end
        end
    else # ----- undirected -----
        v = 1
        while v < N
            mu = rand(1)[1]
            lr = log(1.0 - mu)
            w += 1 + floor(Int, lr/lp)
            while w >= v && v < N
                w -= v
                v += 1
            end
            if v < N
                add_edge(v+1, w+1, graph)
            end
        end
    end
    return graph
end

"""
    Generate a random graph by parsing G(N, \$\\langle k \\rangle\$) where 
    \$\\langle k \\rangle\$ is the desired mean degree of the final graph.

    Args:
        N:
            Total number of nodes of the graph.
        k_mean:
            Expected mean degree of the generated graph.
        is_directed:
            Boolean to signal whether the final graph is undirected or 
            directed.
        self:
            {default=false} Boolean to signal whether self-loops are allowed.
    Return:
        graph:
            'Graph' structure representing the final ER graph with the expected 
            mean degree.
"""
function ER_k(N::Int, k_mean::Float64, is_directed::Bool, self=false)
    p = k_mean/(N-1)
    graph = erdos_renyi_net(N, p, is_directed, self)
    return graph
end

"""
    Generate a random graph by parsing the total number of nodes, expected 
    mean degree and number of edge types.

    Args:
        N:
            Total number of nodes of the graph.
        k_mean:
            Expected mean degree of the generated graph.
        n_types:
            Number of edge types for the final graph.
        is_directed:
            Boolean to signal whether the final graph is undirected or 
            directed.
        self:
            {default=false} Boolean to signal whether self-loops are allowed.
    Return:
        graph:
            'Graph' structure representing the final ER graph with the expected 
            mean degree and number of edge types. This final graph contains an 
            edge property with name "edgetype".
"""
function ER_multi(N::Int, k_mean::Float64, n_types::Int, is_directed::Bool, self=false)
    graph = ER_k(N, k_mean, is_directed, self)
    possible_types = [j for j in 1:n_types]

    edgetypes_prop = [ rand(possible_types) for j in 1:length(graph.edges) ]
    set_edges_properties("edgetype", edgetypes_prop, graph)
    return graph
end

"""
    Specific for exporting the generated Erdos-Renyi random graphs.
    The only metadata exported together with the edgelist is the integer
    "edgetype" property

    Args:
        graph:
            'Graph' structure containing the "edgetype" integer property.
        fout:
            filename to where the edgelist should be exported.
"""
function export_edgefile_csv(graph::Graph, fout::String)
    edges = graph.edges
    edgetype = graph.int_eproperties["edgetype"]
    source_arr, target_arr = Int[], Int[]
    type_arr = Int[]
    for edge in edges
        push!(source_arr, edge.source)
        push!(target_arr, edge.target)
        push!(type_arr, edgetype[edge.index])
    end
    CSV.write(fout, DataFrame([source_arr, target_arr, type_arr], [:Source, :Target, :Type]))
end

# To delete
"""
    Function specific for exporting the generated random networks.
    The only metadata exported together is the "edgetype" property.
"""
function export_edgefile(graph::Graph, fout::String)
    edges = graph.edges
    edgetype = graph.int_eproperties["edgetype"]
    open("$fout.txt", "w") do f
        for edge in edges
            write(f, "$(edge.source)\t$(edge.target)\t$(edgetype[edge.index])\n")
        end
    end
end