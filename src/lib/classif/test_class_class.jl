include("clsintree.jl")
include("ping_class1f.jl")
include("ping_class2f.jl")
using ..DataTypes: classifStruct

function test_class_class(PS, PS0, PS20, PS2, lonS, latS, depthS, nraw, depthInf,
     depthRef, nchan, transectNo, pingFromNo, pingToNo, ping_distance, ping_average)
    # Initialize variables
    cPINGS = copy(PS)
    nClasses = 5 * nraw       # 5 classes per transect
    fPings = 0.95             # fraction threshold

    cCLASS = collect(1:length(depthS))  # class ids array
    nCLASS = ones(Int, length(depthS))  # class counts array
    cDEPTHS = copy(depthS)
    DEPTH0 = depthInf
    # First classification pass
    cCLASS, nCLASS, cPINGS, cDEPTHS = ping_class1f(cPINGS, nClasses, fPings,
     cCLASS, nCLASS, ping_distance, ping_average, cDEPTHS, DEPTH0)

    nClasses = 10
    fPings = 0.90

    cCLASS, nCLASS, cPINGS, cDEPTHS = ping_class2f(cPINGS, nClasses, fPings,
     cCLASS, nCLASS, ping_distance, ping_average, cDEPTHS, DEPTH0)


    # Find mask of classes equal to their own index (1-based)
    msk = findall(i -> cCLASS[i] == i, 1:length(cCLASS))

    # Sort nCLASS for those indices descending
    sorted_idx = sortperm(nCLASS[msk], rev=true)
    omsk = msk[sorted_idx]

    # Select top nClasses classes
    cCs = cCLASS[omsk[1:min(nClasses, length(omsk))]]

    # Create array tCLASS, size length(cCLASS), initialized with NaN
    tCLASS = fill(NaN, length(cCLASS))

    # Populate tCLASS using clsintree function for each index
    for n in 1:length(cCLASS)
        tCLASS[n] = clsintree(cCLASS, n)
    end

    # Reclassify each ping to the closest class centroid in cCs
    rCLASS = fill(NaN, size(PS, 1))

    for n in 1:size(PS, 1)
        dmin = Inf
        mmin = -1
        #= if all(isnan, PS[n, :])
            continue
        end =#
        for (m, c) in enumerate(cCs)
            if all(isnan, cPINGS[c, :])
                continue
            end
            d = ping_distance(cPINGS[c, :], PS[n, :])
            if d < dmin
                dmin = d
                mmin = m
            end
        end
        if mmin != -1
            rCLASS[n] = cCs[mmin]
        else
            # All distances were NaN — leave as NaN
            @warn "No valid distance found for ping $n; setting rCLASS[$n] = NaN"
        end
    end

    CLASSIFICATION = classifStruct(
        nraw,
        depthInf,
        depthRef,
        nchan,
        PS0,
        PS,
        PS20,
        PS2,
        lonS,
        latS,
        depthS,
        nClasses,
        fPings,
        cPINGS,
        cCLASS,
        cCs,
        Int.(tCLASS),
        rCLASS,
        transectNo,
        pingFromNo,
        pingToNo
    )

    return CLASSIFICATION

end