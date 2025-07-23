"""
Parses a GPS NMEA sentence (`GPGGA`, `GPGLL`, `GPGNS`, or `GPGXA`) and extracts time, latitude, and longitude.

### Input
- `nmea::AbstractString`: A raw NMEA GPS sentence (e.g., `"GPGGA,..."`).

### Output
- `GPSDataRAW`: A struct containing the parsed fields:
  - `time::Float64`: Time in fractional hours (UTC), or `-1.0` if parsing fails.
  - `latitude::Float64`: Latitude in decimal degrees (negative if south), or `0.0` if parsing fails.
  - `longitude::Float64`: Longitude in decimal degrees (negative if west), or `0.0` if parsing fails.

### Supported NMEA Sentences
- `GPGGA` (Global Positioning System Fix Data)
- `GPGLL` (Geographic Position – Latitude/Longitude)
- `GPGNS` (Fix Data)
- `GPGXA` (Interim positioning info, treated like GGA)

### Notes
- Latitude is parsed from DDM (Degrees Decimal Minutes) format (e.g., `"6345.1234", "S"`).
- Longitude is parsed similarly (e.g., `"05823.4567", "W"`).
- If any fields are missing or malformed, defaults (`0.0` or `-1.0`) are returned.
- Direction fields (`"N"`, `"S"`, `"E"`, `"W"`) determine sign.
"""
function gpsRead(nmea::AbstractString)::GPSDataRAW
    lPS = GPSDataRAW()

    if length(nmea) > 5
        ss = split(nmea[4:end], ','; keepempty=true)
        sentence_type = ss[1]

        function parse_time(s)
            try
                h = parse(Int, s[1:2])
                m = parse(Int, s[3:4])
                s_val = parse(Int, s[5:6])
                return h + m/60 + s_val/3600
            catch
                return -1.0
            end
        end

        function parse_lat(s, hemi)
            try
                deg = parse(Float64, s[1:2])
                min = parse(Float64, s[3:end])
                val = deg + min / 60
                return hemi == "S" ? -val : val
            catch
                return 0.0
            end
        end

        function parse_lon(s, hemi)
            try
                deg = parse(Float64, s[1:3])
                min = parse(Float64, s[4:end])
                val = deg + min / 60
                return hemi == "W" ? -val : val
            catch
                return 0.0
            end
        end

        if sentence_type == "GGA" && length(ss) >= 15 &&
           !isempty(ss[2]) && !isempty(ss[3]) && !isempty(ss[5]) &&
           isdigit(ss[2][1]) && isdigit(ss[3][1]) && isdigit(ss[5][1])

            lPS.time = parse_time(ss[2])
            lPS.latitude = parse_lat(ss[3], ss[4])
            lPS.longitude = parse_lon(ss[5], ss[6])

        elseif sentence_type == "GLL" && length(ss) >= 5
            lPS.latitude = parse_lat(ss[2], ss[3])
            lPS.longitude = parse_lon(ss[4], ss[5])
            if length(ss) > 6
                lPS.time = parse_time(ss[6])
            end

        elseif sentence_type == "GNS" && length(ss) >= 6
            lPS.time = parse_time(ss[2])
            lPS.latitude = parse_lat(ss[3], ss[4])
            lPS.longitude = parse_lon(ss[5], ss[6])

        elseif sentence_type == "GXA" && length(ss) >= 6
            lPS.time = parse_time(ss[2])
            lPS.latitude = parse_lat(ss[3], ss[4])
            lPS.longitude = parse_lon(ss[5], ss[6])
        end
    end

    return lPS
end
