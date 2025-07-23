"""Signal processing routines for acoustic data (e.g., filtering, FFT)"""
module SignalProcessing

using LinearAlgebra, Statistics
using ..DataTypes: Sample

include("./lib/procs/rangeSlope.jl")
include("./lib/procs/computeBBFrequency.jl")
include("./lib/procs/smoothSeqEcho.jl")
include("./lib/procs/smoothRange.jl")


export rangeSlope, computeBBFrequency, smoothSeqEcho, smoothRange

end