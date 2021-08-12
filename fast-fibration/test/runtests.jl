using FastFibration
using Test

@testset "FastFibration.jl" begin
    # Testing vertex obj
    @test FastFibration.Vertex(0).index == 0
    @test length(FastFibration.Vertex(0).edges_source) == 0
    @test length(FastFibration.Vertex(0).edges_target) == 0

    # Testing initialization algorithm for fibration
    # Open files
    graph_test_1 = FastFibration.graph_from_csv("../data/test_1.csv", true)
    graph_test3scc = FastFibration.graph_from_csv("../data/test_3SCC.csv", true)
    graph_test3scc2 = FastFibration.graph_from_csv("../data/test_3SCC_2.csv", true)
    graph_test6scc = FastFibration.graph_from_csv("../data/test_6SCC.csv", true)
    
    part_test1, pq_test1 = FastFibration.initialize(graph_test_1)
    part_test3scc, pq_test3scc = FastFibration.initialize(graph_test3scc)
    part_test3scc2, pq_test3scc2 = FastFibration.initialize(graph_test3scc2)
    part_test6scc, pq_test6scc = FastFibration.initialize(graph_test6scc)

end
