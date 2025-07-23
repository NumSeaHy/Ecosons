using LinearAlgebra   # for conj()
using Compat         

"""
Compute phase angles from waveform matrix `W` for different beam types `bt`.

# Arguments
- `W::AbstractMatrix{<:Complex}`: Matrix of complex waveform signals. Each row corresponds to a time/sample,
  columns correspond to different sectors/signals.
- `bt::Int`: Beam type identifier.

# Returns
- `paAt`: Phase angle related to "Along Track" direction.
- `paAl`: Phase angle related to "Along Line" direction.

# Beam types handled:
- 1: Four sectors - Starboard Aft, Port Aft, Port Fore, Starboard Fore
- 17: Three sectors - Starboard Aft, Port Aft, Forward
- 49, 65, 81: Three sectors + center element
- 97: Four sectors - Fore Starboard, Aft Port, Aft Starboard, Fore Port
"""
function phaseAngle(W::AbstractMatrix{<:Complex}, bt::Int)
    # Determine size of W and compute product of all but last dimension (to flatten accordingly)
    sW = size(W)
    L = prod(sW[1:end-1])  # Product of dimensions except last (assuming last dim is signals)
    
    # Initialize output arrays with zeros, shaped like input without the last dimension
    # In Julia, we just keep it as a vector with length L or reshape accordingly
    # Here, we will assume W is 2D: rows = samples, columns = signals (sectors)
    paAt = zeros(Float64, sW[1])  # one value per sample
    paAl = zeros(Float64, sW[1])
    
    # Define a shorthand for angle since Julia uses angle() not arg()
    ang(x) = angle(x)
    
    # Process according to beam type
    if bt == 1
        # Four sectors: Starboard Aft, Port Aft, Port Fore, Starboard Fore
        # Calculate phase angles based on combinations of sectors
        # conj(W[:,1]+W[:,2]) .* (W[:,3]+W[:,4]) is element-wise multiplication of complex vectors
        paAl .= ang.(conj.(W[:,1] .+ W[:,2]) .* (W[:,3] .+ W[:,4]))
        paAt .= ang.(conj.(W[:,2] .+ W[:,3]) .* (W[:,1] .+ W[:,4]))
        
    elseif bt == 17
        # Three sectors: Starboard Aft, Port Aft, Forward
        paAl .= (ang.(conj.(W[:,1]) .* W[:,3]) .+ ang.(conj.(W[:,2]) .* W[:,3])) ./ sqrt(3)
        paAt .= ang.(conj.(W[:,2]) .* W[:,3]) .- ang.(conj.(W[:,1]) .* W[:,3])
        
    elseif bt in (49, 65, 81)
        # Three sectors + center element: Starboard Aft, Port Aft, Forward, Centre
        paAl .= (ang.(conj.(W[:,1] .+ W[:,4]) .* (W[:,3] .+ W[:,4])) .+ ang.(conj.(W[:,2] .+ W[:,4]) .* (W[:,3] .+ W[:,4]))) ./ sqrt(3)
        paAt .= ang.(conj.(W[:,2] .+ W[:,4]) .* (W[:,3] .+ W[:,4])) .- ang.(conj.(W[:,1] .+ W[:,4]) .* (W[:,3] .+ W[:,4]))
        
    elseif bt == 97
        # Four sectors: Fore Starboard, Aft Port, Aft starboard, Fore Port
        paAt .= ang.(conj.(W[:,2]) .* W[:,1])
        paAl .= ang.(conj.(W[:,4]) .* W[:,3])
        
    else
        error("Unsupported beam type: $bt")
    end
    
    return paAt, paAl
end
