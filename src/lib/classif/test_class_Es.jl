include("calc_Es.jl")
using Printf
function test_class_Es(CLASSIFICATION, fname)
    if CLASSIFICATION.nchan == 1
        ES_definitions = [
            ("E1", 100, 5), ("E2", 100, 5),
            ("E1", 90, 5), ("E2", 90, 5),
            ("E1", 80, 5), ("E2", 80, 5),
            ("E1", 70, 5), ("E2", 70, 5),
            ("E1", 60, 5), ("E2", 60, 5),
            ("E1", 50, 5), ("E2", 50, 5)
        ]
    else
        ES_definitions = [
            ("E1", 100, 5), ("E2", 100, 5),
            ("E1", 90, 5), ("E2", 90, 5),
            ("E1", 80, 5), ("E2", 80, 5),
            ("E1", 70, 5), ("E2", 70, 5),
            ("E1", 60, 5), ("E2", 60, 5),
            ("E1", 50, 5), ("E2", 50, 5)
        ]
    end

    EsValues0 = calc_Es(ES_definitions, CLASSIFICATION.PS0, CLASSIFICATION.PS20)
    EsValues = calc_Es(ES_definitions, CLASSIFICATION.PS, CLASSIFICATION.PS2)

    filename = joinpath(fname, "test_class-Edata_ch$(CLASSIFICATION.nchan).dat")
    open(filename, "w") do f
        # Header
        print(f, "ID,lat,lon,depth,class")
        for (name, dist, _) in ES_definitions
            print(f, ",$(name)_$(dist)")
        end
        println(f)

        for n in 1:length(CLASSIFICATION.tCLASS)
            id = 1_000_000 * CLASSIFICATION.transectNo[n] + CLASSIFICATION.pingFromNo[n]
            lat = CLASSIFICATION.latS[n]
            lon = CLASSIFICATION.lonS[n]
            depth = CLASSIFICATION.depthS[n]
            cls_idx = findfirst(==(CLASSIFICATION.tCLASS[n]), CLASSIFICATION.cCs)
            @printf(f, "%d,%.6f,%.6f,%.2f,%d", id, lat, lon, depth, isnothing(cls_idx) ? NaN : cls_idx)

            # Print all ES values
            for m in 1:size(EsValues, 1)
                @printf(f, ",%.6f", EsValues[m, n])
                #@printf(f, ",%.6f", EsValues0[m, n])
            end
            println(f)
        end
    end
end