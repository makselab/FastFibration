"""
    Set a mapping properties for the vertices.

    Depending on the type of the elements of 'arr' the
    properties are set in different variables.

    If there is already a property with the given 'name',
    the function will replace the old array with the new
    one, without any warning.

    'name':
        name of the property.
    'arr':
        array of typed elements.
    'graph':
        graph to be assigned with the property.
"""
function set_vertices_properties(name::String, arr::Array{Int}, graph::Graph)
    if length(graph.vertices) == length(arr)
        graph.int_vproperties[name] = arr
    else
        print("size array does not match number of vertices\n")
    end
end

function set_vertices_properties(name::String, arr::Array{Float64}, graph::Graph)
    if length(graph.vertices) == length(arr)
        graph.float_vproperties[name] = arr
    else
        print("size array does not match number of vertices\n")
    end
end

function set_vertices_properties(name::String, arr::Array{String}, graph::Graph)
    if length(graph.vertices) == length(arr)
        graph.string_vproperties[name] = arr
    else
        print("size array does not match number of vertices\n")
    end
end

"""
    Set a mapping properties for the edges.

    Depending on the type of the elements of 'arr' the
    properties are set in different variables.

    If there is already a property with the given 'name',
    the function will replace the old array with the new
    one, without any warning.
        
    'name':
        name of the property.
    'arr':
        array of typed elements.
    'graph':
        graph to be assigned with the property.
"""
function set_edges_properties(name::String, arr::Array{Int}, graph::Graph)
    if length(graph.edges) == length(arr)
        graph.int_eproperties[name] = arr
    else
        print("size array does not match number of edges\n")
    end
end

function set_edges_properties(name::String, arr::Array{Float64}, graph::Graph)
    if length(graph.edges) == length(arr)
        graph.float_eproperties[name] = arr
    else
        print("size array does not match number of edges\n")
    end
end

function set_edges_properties(name::String, arr::Array{String}, graph::Graph)
    if length(graph.edges) == length(arr)
        graph.string_eproperties[name] = arr
    else
        print("size array does not match number of edges\n")
    end
end

"""
    Print all the properties associated with 'graph'.

    graph:
        Graph object.
"""
function list_properties(graph::Graph)
    print("$(keys(graph.int_vproperties)) - Int - Vertex\n")
    print("$(keys(graph.float_vproperties)) - Float - Vertex\n")
    print("$(keys(graph.string_vproperties)) - String - Vertex\n")

    print("$(keys(graph.int_eproperties)) - Int - Edge\n")
    print("$(keys(graph.float_eproperties)) - Float - Edge\n")
    print("$(keys(graph.string_eproperties)) - String - Edge\n")
end