using Revise
includet("../src/EA400Load.jl")
using .EA400Load

DATA, SIZE = load(1, "./data/*raw");

printpath("./data/*raw")