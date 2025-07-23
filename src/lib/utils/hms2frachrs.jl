"""Convert [hour, min, sec] to fractional hours"""
function hms2t(hms::AbstractVector{<:Real})
    t = hms[1]
    if length(hms) > 1
        t += hms[2] / 60
    end
    if length(hms) > 2
        t += hms[3] / 3600
    end
    return t
end
