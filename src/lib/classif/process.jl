include("../utils/latlon2utmxy.jl")
include("../procs/getFirstHit.jl")
include("pingStretch.jl")
include("pingCorrect.jl")
include("../formats/simradRAW.jl")


function process()
    dir = joinpath(@__DIR__, "..", "data", "EA400")
    files = filter(f -> endswith(f, ".raw"), readdir(dir))
    full_paths = joinpath.(dir, files)

    Dref = 5.0
    Dmax = 40.0
    DnField = 2.5  # (unused in snippet, kept for completeness)

    for fname in fnames
        # fmt_simradRAW returns (P, H, G)
        P, H, G = simradRAW(fname)

        P38 = P[1]
        H38 = H[1]
        P200 = P[2]
        H200 = H[2]

        # Assuming G.latitude and G.longitude are vectors
        Xp, Yp = latlon2utmxy(-1, G.latitude, G.longitude)

        NP = size(P200, 1)

        D = fill(NaN, NP)
        R200 = fill(NaN, NP)
        R38 = fill(NaN, NP)

        for np in 1:NP
            R200[np] = getFirstHit(P200[np, :], H200[np], 1.0, 30, 60)
            R38[np] = round(Int, R200[np] * H200[np].sampleInterval / H38[np].sampleInterval)
            D[np] = 0.5 * R200[np] * H200[np].sampleInterval * H200[np].soundVelocity
        end

        R38max = maximum(R38)
        R200max = maximum(R200)
        Dmax = maximum(D)
        Dref = 5.0

        PP200 = fill(NaN, NP, R200max)
        PP38 = fill(NaN, NP, R38max)

        for np in 1:NP
            PP200[np, :] = pingStretch(P200[np, :], R200[np], R200max)
            PP38[np, :] = pingStretch(P38[np, :], R38[np], R38max)

            PP200[np, :] = pingCorrect(PP200[np, :], D[np], Dref, Dmax, H200[np].absorptionCoefficient / 1000, 30)
            PP38[np, :] = pingCorrect(
                PP38[np, :], D[np], Dref, Dmax, H38[np].absorptionCoefficient / 1000, 30
            )
        end
    end

    return PP38, PP200
end