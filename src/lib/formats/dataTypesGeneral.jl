module DataTypesGeneral
mutable struct TransectCross
    lon1::Vector{Float64}
    lat1::Vector{Float64}
    lon2::Vector{Float64}
    lat2::Vector{Float64}
    transect1::Vector{Int}
    transect2::Vector{Int}
    nping1::Vector{Int}
    nping2::Vector{Int}
    ddepth::Vector{Float64}

    # Optional fields (e.g. for later population)
    utmZN::Union{Int, Nothing}
    utmX1::Union{Vector{Float64}, Nothing}
    utmY1::Union{Vector{Float64}, Nothing}
    utmX2::Union{Vector{Float64}, Nothing}
    utmY2::Union{Vector{Float64}, Nothing}

    function TransectCross()
        new([], [], [], [], [], [], [], [], [], nothing, nothing, nothing, nothing, nothing)
    end
end

mutable struct Slope
    slope::Vector{Float64}
    trans_dir::Vector{Float64}
    cang::Vector{Float64}
end

mutable struct Bathymetry
    name::String
    time::Vector{Float64}
    latitude::Vector{Float64}
    longitude::Vector{Float64}
    depth::Vector{Float64}
end

struct classifStruct
    nraw::Int64
    depthInf::Float64
    depthRef::Float64
    nchan::Int64
    PS0::Matrix{Float64}
    PS::Matrix{Float64}
    PS20::Matrix{Float64}
    PS2::Matrix{Float64}
    lonS::Vector{Float64}
    latS::Vector{Float64}
    depthS::Vector{Float64}
    nClasses::Int64
    fPings::Float64
    cPINGS::Matrix{Float64}
    cCLASS::Vector{Int64}
    cCs::Vector{Int64}
    tCLASS::Vector{Int64}
    rCLASS::Vector{Float64}
    transectNo::Vector{Int64}
    pingFromNo::Vector{Int64}
    pingToNo:: Vector{Int64}
   
end

export TransectCross, Slope, Bathymetry, classifStruct

end