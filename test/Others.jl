using Ecosons
using Test

@testset begin
    file_name = joinpath(@__DIR__, "..", "data", "test1.csv")
    cols, hdrs = csvreadcols(file_name)
    @show hdrs  # Should be ["name", "age", "height"]
    @show cols[1]  # ["Alice", "Bob", "Charlie"]
    @show cols[2]  # [30.0, 25.0, 28.0]
    @show cols[3]  # [5.5, 6.1, 5.9]
    ec = extractCols(hdrs, cols, "age", "height")
    @show ec[1]  # [30.0, 25.0, 28.0]
    @show ec[2]  # [5.5, 6.1, 5.9]

    file_name = joinpath(@__DIR__, "..", "data", "test1.tsv")
    cols, hdrs = tsvreadcols(file_name; hdr = true)
    @show hdrs  
    @show cols[1]  
    @show cols[2]  
    @show cols[3] 

    file_name = joinpath(@__DIR__, "..", "data", "test2.csv")
    cols, hdrs = csvreadcols(file_name; csvsep = ';', hdr = false)
    @show hdrs  # Should be [1, 2, 3]
    @show cols[1]  # ["John", "Doe", "Jane"]
    @show cols[2]  # [35.0, 40.0, 22.0]
    @show cols[3]  # [5.8, 6.0, 5.4]

    ec = extractCols(hdrs, cols, 2)
    @show ec[1]  # [35.0, 40.0, 22.0]

    file_name = joinpath(@__DIR__, "..", "data", "test3.csv")
    cols, hdrs = csvreadcols(file_name)
    @show hdrs  # ["id", "score", "note"]
    @show cols[1]  # [1.0, 2.0, 3.0]
    @show cols[2]  # [99.5, NaN, 85.0]
    @show cols[3]  # ["Excellent", "Good", "Average"]

    @show parseFnameDate("log_20250617.txt", "log_yyyyMMdd.txt")  # (2025, 6, 17)
    @show parseFnameDate("track_2023_12_31.csv", "track_yyyy_mm_dd.csv")  # (2023, 12, 31)
    @show parseFnameDate("202504-data.txt", "yyyymm-data.txt")  # (2025, 4, missing)

    s = """ "a", "b", "c d" """
    parsed = parseCSVline(s, ',')
    @show parsed  # ["a", "b", "c d"]

    @show allbut(["a", "b", "c", "d"], ["b", "d"])  # ["a", "c"]

    P = rand(5, 100) .* 30 .- 20  # 5 signals of 100 samples in dB
    nfr = [10, 20, 15, 30, 25]
    nto = [60, 70, 65, 80, 75]

    resampled = resampleANDrescale(P, nfr, nto, 50, "linear")

    # TEST CreateMatrices
    # Create a 2D matrix with a gradient and noise
    M = [x + 0.5 * randn() for x in 1:100, y in 1:50]
    min_v = minimum(M)
    max_v = maximum(M)

    file_name = joinpath(@__DIR__, "..", "data", "example.pgm")
    # Save to a grayscale PGM file
    matrix2PGM(M, file_name, min_v, max_v)

    # Create three color channel matrices (red, green, blue)
    Mr = [sin(x/10) + rand()*0.1 for x in 1:100, y in 1:50]
    Mg = [cos(y/10) + rand()*0.1 for x in 1:100, y in 1:50]
    Mb = [sin(x/10) * cos(y/10) for x in 1:100, y in 1:50]

    min_v = -1
    max_v = 1

    # Save to an RGB PPM file
    file_name = joinpath(@__DIR__, "..", "data", "example_rgb.ppm")
    matrix2PPM_RGB(Mr, Mg, Mb, file_name, min_v, max_v)

    # Generate a smooth matrix for visualization
    M = [sin(x / 10) * cos(y / 20) for x in 1:200, y in 1:100]

    min_v = -1
    max_v = 1

    # Save to a false-color PPM file
    file_name = joinpath(@__DIR__, "..", "data", "example_colormap.ppm")
    matrix2PPM(M, file_name, min_v, max_v)

    # TEST plot_data_from_file
    file_name = joinpath(@__DIR__, "..", "data", "test1.csv")
    plot_data_from_file(file_name, "age", "height"; file_format = "csv")

        
    file_name = joinpath(@__DIR__, "..", "data", "test1.tsv")
    plot_data_from_file(file_name, "Longitude", "Latitude"; file_format = "tsv")

end