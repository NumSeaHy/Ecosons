# Loading packages
# using Revise

# Load modules
include("EA400Load.jl")

using .EA400Load

file_pattern = "./data/*raw"
channel = 1

# Load all the files
data, dim = load(channel, file_pattern);

# # Call to the function that calculates where is the bin associated with the first hit
# baths = processBathymetries(data, dim, getFirstHit)

# # Transform the bins to depth
# for i in 1:dim
#     baths[i].depth = 0.5 * baths[i].depth * data[i].Q[1].sampleInterval * data[i].Q[1].soundVelocity
# end

# plot_bathymetry_line(1:length(baths[1]plot_bathymetry_line.depth), -baths[1].depth)


# # Plot the echogram to file number 4
# ec_plot_echobottom(data[4].P)


# # Plot the bathymetry and see some anomalous points
# plot_bathymetry_line(1:size(data[4].P,1), -bath1)

# # Smooth the bathymetry to avoid anomalous points
# smoothRange!(bath1, 6, 3)

# # Plot the smoothed bathymetry
# plot_bathymetry_line(1:length(baths[4].depth), -baths[4].depth)

# # Tide correction

# fname = "./data/tide.dat"

# baths[1].depth

# tidecorrectDay!(baths[1], fname)



