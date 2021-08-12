
function get_initial_state(graph::Graph, eprop_name="edgetype")
    if !graph.is_directed
        print("Undirected network\n")
        return
    end

    edgetype_prop = graph.int_eproperties[eprop_name]
    number_edgetype = length(collect(Int, Set(edgetype_prop)))

    partition, pivot_queue = initialize(graph)
    return partition, pivot_queue
end

function array2string(arr::Array)
    final_str = ""
    for j in 1:length(arr)
        final_str = final_str*"$(arr[j])"
    end
    return final_str
end

"""
    Function to compare if two partitions of fibers are equivalent. It is an auxiliary 
    function to be used for unit testing.

    Args:
        part1:

        part2:

    Result:
        equal:
            Boolean value. 'true' if the two parsed partitions are equivalent. 'false'
            otherwise.
"""
function compare_partitions(part1::Array{Fiber}, part2::Array{Fiber})
    return
end