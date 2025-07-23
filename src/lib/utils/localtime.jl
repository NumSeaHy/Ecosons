using Dates

"""Convert a UNIX timestamp `t` (seconds since the UNIX epoch) into a named tuple 
representing local time components."""
function localtime(t::Float64)
    dt = Dates.unix2datetime(Int(round(t)))
    hour = Dates.hour(dt)
    minute = Dates.minute(dt)
    seconds = Dates.second(dt)
    microsecond = Dates.millisecond(dt)*1000
    year = Dates.year(dt) - 1900
    mon = Dates.month(dt) - 1
    mday = Dates.day(dt)
    return (hour + (minute + (seconds + microsecond / 1e6) / 60) / 60)

end