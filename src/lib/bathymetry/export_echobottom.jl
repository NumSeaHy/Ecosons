using Printf

"""
Export bottom depth data from a `SonarDataRAW` object to a fixed-width ASCII text file.

# Arguments
- `data::SonarDataRAW`: The sonar data structure containing at least:
    - `P`: Echo power matrix.
    - `R`: Bottom detection vector (range/bin index).
    - `G`: GPS and time metadata per ping.
    - `name`: Transect or survey name.
- `transect::Int`: Numeric transect identifier to include in the export.
- `dir::String`: Path to the output text file.
- `ping_step::Int=1`: Interval for subsampling pings (e.g., `ping_step=2` writes every second ping).

# Output
Creates a fixed-width ASCII file with columns:
- `ID`: Ping index in the output file.
- `T_NUM`: Transect number (user-specified).
- `T_NAME`: Transect or dataset name from `data.name`.
- `N_PING`: Ping index in the original data.
- `LAT`: Latitude in decimal degrees (or "NaN" if missing).
- `LON`: Longitude in decimal degrees (or "NaN" if missing).
- `DEPTH`: Computed true depth from bottom detection, adjusted via `convert_true_depth`.
"""
function export_echobottom(
    data::SonarDataRAW,
    transect::Int,
    dir::String;
    ping_step::Int = 1,
    )

    # Validate inputs
    if isnothing(data)
        error("Error: No sonar data provided.")
    end

    if !(isa(transect, Int) && transect > 0)
        error("Error: transect must be a positive integer.")
    end

    if !(isa(dir, String) && !isempty(dir))
        error("Error: output path must be a non-empty string.")
    end

    if ping_step < 1
        error("Error: ping_step must be >= 1.")
    end

    if !hasfield(typeof(data), :P) || isempty(data.P)
        error("Error: P is missing or empty.")
    end

    if !hasproperty(data, :R) || isnothing(data.R)
        error("Error: SonarDataRAW does not contain valid bottom detection data (R).")
    end

    # Proceed to open file and write
    try
        open(dir, "w") do fout
            # Print fixed-width header
            println(fout,
                rpad("#ID",6)*" "*rpad("T_NUM",6)*" "*rpad("T_NAME",30)*" "*rpad("N_PING",7)*" "*rpad("LAT",12)*" "*rpad("LON",12)*" "*rpad("DEPTH",8)
            )
            ping_id = 0

            for n in 1:ping_step:size(data.P, 1)
                depth = convert_true_depth(data.R[n] - 2, data; ping = n)
                ping_id += 1

                if data.G[n].time > 0
                    @printf(fout, "%-6d %-6d %-30s %-7d %-12.6f %-12.6f %-8g\n",
                        ping_id, transect, data.name, n,
                        data.G[n].latitude, data.G[n].longitude, depth)
                else
                    @printf(fout, "%-6d %-6d %-30s %-7d %-12s %-12s %-8g\n",
                        ping_id, transect, data.name, n,
                        "NaN", "NaN", depth)
                end
            end
        end
    catch e
        error("Error writing to file: $(e)")
    end

    println("Echobottom data exported to $(dir)!")
end
