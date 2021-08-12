#=
    Utility functions to handle I/O graph from edgefiles.
=#

"""
    Create graph from CSV file.

    The file must contain as header the columns: 'Source', 'Target' 
    and (optional)'Type'. The indexes of the vertices must be
    integers and withing the range [1,N], where N is the total
    number of vertices in the graph.

    Args:
        file_path:
            String containing the path to the CSV file.
        is_directed:
            {true, false} boolean value to signal whether the
            network is directed(true) or undirected(false).
    Return:
        graph:
            'Graph' structure representing the CSV edgelist file. This
            object contains at least the integer edge property called
            'edgetype'.
"""
function graph_from_csv(file_path::String, is_directed::Bool)
    df = CSV.File(file_path) |> DataFrame
    graph = Graph(is_directed)
    N = maximum([maximum(df.Source), maximum(df.Target)])

    # Create the vertices
    for i in 1:N
        add_node(graph)
    end
    # Add the connections
    for j in 1:length(df.Source)
        add_edge(df.Source[j], df.Target[j], graph)
    end
    if "Type" in names(df)
        if typeof(df.Type[1])==Int
            set_edges_properties("edgetype", df.Type, graph)
        # Converts the string types to integer type.
        elseif typeof(df.Type[1])==String
            unique_types = collect(Set(df.Type))
            label_map = Dict{String, Int}()
            for j in 1:length(unique_types)
                label_map[unique_types[j]] = j
            end
            new_int_edgeprop = [label_map[j] for j in df.Type]
            types = [ df.Type[j] for j in 1:length(df.Type)]
            set_edges_properties("edgetype", new_int_edgeprop, graph)
            set_edges_properties("edgetype", types, graph)
        else
            error("Format of 'Type' column is not accepted.")
        end
    else
        set_edges_properties("edgetype", [1 for i in 1:graph.M], graph)
    end
    return graph
end

"""
    Create graph from edgelist.
    edgelist is an array of dimension M x 2 containing
    the source and target of each edge.
    The function assumes that the vertices are labeled
    from 1 to N.
"""
function graph_from_edgelist(edgelist::Array{Int, 2}, is_directed::Bool)
    graph = Graph(is_directed)
    N = maximum([maximum(edgelist[:,1]), maximum(edgelist[:,2])])

    # -- Create the vertices --
    for j in 1:N
        add_node(graph)
    end
    # -- Then, build the connections
    for j in 1:length(edgelist[:,1])
        add_edge(edgelist[j,1], edgelist[j,2], graph)
    end
    return graph
end

"""
    Given a formatted edgelist file, it returns two objects: a N x 2
    array containing the edgelist with format [[src,tgt], ...] and 
    a array of string arrays containing all the other columns in the file.

    Example:
    file -> "1 2 prop1 prop2
             2 3 prop1 prop2
             ... ..... ....."

    returns ->
    [1 2; 2 3; ...] and [["prop1", "prop2"], ["prop1", "prop2"], ...]
"""
function process_edgefile(fname::String, convert_int=false)
    src_tgt = Array{String}[]
    edge_prop = Array{String}[]
    
    open(fname, "r") do f
        for line in eachline(f)
            line_elem = split(line)
            elem1 = [ line_elem[1], line_elem[2] ]
            #elem1 = Int[parse(Int, line_elem[1]), parse(Int, line_elem[2])]

            append!(src_tgt, [elem1])
            append!(edge_prop, [line_elem[3:length(line_elem)]])
        end
    end

    src_tgt = reduce(hcat, src_tgt)
    edges = permutedims(src_tgt)
    if convert_int
        edges = parse.(Int, edges)
    end
    return edges, edge_prop
end

"""
    Process the edge properties returned by function 'process_edgefile'.
    
    As returned from 'process_edgefile', eprops is an array containing
    string arrays with the properties' values for each edge.

    For example, 'eprops' holds two string arrays if the edgefile has two
    extra columns. The size of these arrays are equal to the number of edges.
    For this, 'names' represents the arrays with the string names for each 
    column.

    Returns a dictionary where the keys are the names in 'names' and the
    values are arrays with the edge properties indexed from 1 to M. 
"""
function process_eprops(eprops::Array{Array{String}}, names::Array{String})
    container = Array{String}[]
    n_props = length(eprops[1])
    for j in 1:n_props
        append!(container, [String[]])
    end
    for j in 1:length(eprops)
        for k in 1:n_props
            append!(container[k], [eprops[j][k]])
        end
    end

    holder = Dict{String, Array{String}}()
    for (j, name) in enumerate(names)
        holder[name] = container[j]
    end
    return holder
end

"""

"""
function create_indexing(edges::Array{String,2})
    unroll = reduce(vcat, edges)
    unroll = collect(Set(unroll))
    N = length(unroll)

    hash = Dict{String, Int}()
    for (j, name) in enumerate(unroll)
        hash[name] = j
    end

    M, dummy = size(edges)
    new_edges = Array{Int}[]
    for j in 1:M
        u = hash[edges[j,1]]
        v = hash[edges[j,2]]
        append!(new_edges, [[u, v]])
    end
    new_edges = copy(transpose(reduce(hcat, new_edges)))
    return new_edges, hash
end

"""
    Read edgelist, create and prepare the graph for the application of the fast 
    fibration algorithm.

    The expected edgelist has 3 columns: the source column, the target column and
    the edgetype column.

    The source and target must be integers ranging from 1 to N, where N is the total
    number of nodes of the graph. The third column can be strings with the unique
    values for each type. These edgetypes will be set as edge integer properties 
    ranging from 1 to K, where K is the total number of unique types.

    Returns a graph object 'graph' containing the integer edge property called
    'edgetype'.
"""
function load_net(fname::String, is_directed::Bool, convert_int=false, etype_col="Column 1")
    edges, eprops = process_edgefile(fname, convert_int)
    # -- if the source and target columns need to be transformed to the interval 1 to
    # -- N, then we create a mapping 'name_map' for each unique value of the nodes.
    if !convert_int
        edges, name_map = create_indexing(edges)
    end
    # -- Save the original string indexes of nodes as 'node_name' vertex property --
    graph = graph_from_edgelist(edges, is_directed)
    N = graph.N
    nodes_name = [ "" for j in 1:N ]
    if !convert_int
        keys_name = collect(keys(name_map))
        for key in keys_name
            nodes_name[name_map[key]]*=key
        end
        set_vertices_properties("node_name", nodes_name, graph)
    end

    if length(eprops[1])!=0
        col_names = [ "Column $j" for j in 1:length(eprops[1]) ]
        fmt_eprops = process_eprops(eprops, col_names)
    end

    edgetype_str = collect(String, Set(fmt_eprops[etype_col]))
    edgetype_map = Dict{String, Int}()
    for (j, value) in enumerate(edgetype_str)
        edgetype_map[value] = j 
    end

    int_edgetypes = Int[]
    for (j, etype_str) in enumerate(fmt_eprops[etype_col])
        push!(int_edgetypes, edgetype_map[etype_str])
    end
    set_edges_properties("edgetype", int_edgetypes, graph)

    return graph, fmt_eprops
end