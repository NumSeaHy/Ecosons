"""Selects certain transects in the sonar data"""
module SelectData

using ..DataTypes: SonarDataRAW

"""Selects indices of sonar transects from `SONAR_DATA` that are closest to a given geographic coordinate `(latitude, longitude)`."""
function select_data(SONAR_DATA, latlon; nmaxtr=1)
    # Validate latlon input
    if length(latlon) != 2
        error("Wrong point specification: latlon must be a tuple or array of length 2.")
    end
    lat, lon = latlon

    # Validate nmaxtr input
    if !(isa(nmaxtr, Integer) && nmaxtr > 0)
        nmaxtr = 1
    end

    # Initialize distance and transect index arrays with NaNs (Float64)
    disttr = fill(NaN, nmaxtr)
    numbtr = fill(NaN, nmaxtr)

    for (n, data) in enumerate(SONAR_DATA)
        G = data.G
        for p in G
            if p.time > 0
                # Calculate squared distance from (lat, lon)
                d = (p.latitude - lat)^2 + (p.longitude - lon)^2

                # Check if this transect n is already recorded
                existing_idx = findfirst(x -> x == n, numbtr)

                if existing_idx !== nothing
                    # If new distance is smaller, update arrays
                    if d < disttr[existing_idx]
                        inds_a = [i for i in eachindex(numbtr) if !isnan(numbtr[i]) && numbtr[i] != n && disttr[i] < d]
                        inds_b = [i for i in eachindex(numbtr) if !isnan(numbtr[i]) && numbtr[i] != n && disttr[i] > d]

                        disttr = vcat(disttr[inds_a], d, disttr[inds_b])
                        numbtr = vcat(numbtr[inds_a], n, numbtr[inds_b])
                    end
                else
                    # Insert new transect if it is closer than existing ones or if there's empty space (NaN)
                    if any(x -> (x > d) || isnan(x), disttr)
                        inds_a = [i for i in eachindex(disttr) if disttr[i] < d]
                        inds_b = [i for i in 1:length(disttr)-1 if disttr[i] > d]

                        disttr = vcat(disttr[inds_a], d, disttr[inds_b])
                        numbtr = vcat(numbtr[inds_a], n, numbtr[inds_b])
                    end
                end

                # Ensure arrays length stays fixed to nmaxtr, fill with NaN if shorter
                if length(disttr) < nmaxtr
                    disttr = vcat(disttr, fill(NaN, nmaxtr - length(disttr)))
                    numbtr = vcat(numbtr, fill(NaN, nmaxtr - length(numbtr)))
                elseif length(disttr) > nmaxtr
                    disttr = disttr[1:nmaxtr]
                    numbtr = numbtr[1:nmaxtr]
                end
            end
        end
    end

    # Filter out NaN entries and return integer indices
    SONAR_DATA_SELECTION = Int.(filter(!isnan, numbtr))
    return SONAR_DATA_SELECTION
end


export select_data


end 
