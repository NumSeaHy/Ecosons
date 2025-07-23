include("lowranceSL1.jl")
include("lowranceSL2.jl")

function lowranceSLG(fname::String)
    # Open file for reading in little-endian binary mode
    open(fname, "r") do f
        # Read header (first two uint16 values)
        slF = read(f, UInt16)
        slV = read(f, UInt16)
        # Note: slB and sl_ fields commented out in original, ignored here

        # Dispatch based on slF (format)
        if slF == 1
            # Call SL1 parser (you need to implement or import fmt_lowranceSL1)
            return lowranceSL1(fname)
        elseif slF == 2
            # Call SL2 parser
            return lowranceSL2(fname)
        else
            error("Format SL$(slF) not yet supported")
        end
    end
end