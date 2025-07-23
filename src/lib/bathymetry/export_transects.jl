function export_transects(
    ntr::Vector{Int}, 
    utmCoords::Bool, 
    xCoord::Vector{Float64}, 
    yCoord::Vector{Float64}, 
    znCoord::Float64, 
    export_file::String;
    n_step::Int = 1, 
    )

    # If no input data provided, return message
    if isempty(ntr)
        return error("No bathymetry data available")
    end

    # Try open file
    try
        open(export_file, "w") do io
            # Write header
            if utmCoords
                println(io, "#ID\tT_NUM\tUTM-X($(znCoord[1]))\tUTM-Y")
            else
                println(io, "#ID\tT_NUM\tLAT\tLON")
            end

            # Write data lines with subsampling
            for n in 1:n_step:length(ntr)
                line = string(n, '\t', ntr[n])
                if utmCoords
                    line *= string('\t', round(xCoord[n], digits=2), '\t', round(yCoord[n], digits=2))
                else
                    line *= string('\t', round(yCoord[n], digits=6), '\t', round(xCoord[n], digits=6))
                end
                println(io, line)
            end
            println("File $(export_file) created!")
        close(io)
        end
    catch e
        println("File $export_file could not be opened for writing: $(e.msg)")
    end
end
