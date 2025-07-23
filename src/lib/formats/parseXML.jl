"""
Recursively parses an XML string `txt` starting at position `tagB`, returning a nested dictionary 
representation of the XML content.

Arguments:
- `txt`: The XML string to parse.
- `xmlin`: (Optional) Dictionary used as the root for parsed XML. Default is a root tag `"."`.
- `tagB`: (Optional) Start index in `txt`. Defaults to 1.

Returns:
- `xmlout`: A `Dict{String,Any}` representing the parsed XML tree.
- `tagC`: `Bool`, indicating whether a closing tag was found for `xmlin`.
- `p`: The position in the string after the parsed content.

Each XML element is represented as a dictionary with keys:
- `"__name"`: The tag name.
- `"__prefix"`: (Optional) Namespace prefix.
- `"__content"`: (Optional) Text content inside the tag.
- `"_attr"`: Keys beginning with `_` represent XML attributes.
- Children with the same tag name are stored as arrays.
"""
function parseXML(txt::String, xmlin::Dict{String, Any}=Dict{String, Any}("__name" => "."), tagB::Int=1)
    xmlout = deepcopy(xmlin)
    tagC = false
    p = tagB
    txt = replace(replace(txt, '\n' => " "), '\r' => "")

    while p < lastindex(txt)
        stxt = txt[p:min(p+1024, end)]
        try
            match(r"^.*$", stxt)  # force UTF-8 decode test
        catch
            stxt = stxt[1:end-1]
        end

        if occursin(r"^</" * xmlout["__name"] * r"\s*>", stxt)
            tagC = true
            p += findfirst(r"^</" * xmlout["__name"] * r"\s*>", stxt).stop
            break
        end
        m = match(r"^\s+", stxt)
        if m !== nothing
            p += length(m.match)
            continue
        end
        m = match(r"^<\?xml\s[^?]+\?>", stxt)
        if m !== nothing
            p += length(m.match)
            continue
        end

        m = match(r"^<([a-zA-Z0-9:]+)\s*((?:[a-zA-Z0-9:]+=(?:\"[^\"]+\"|'[^']+')\s*)+)\s*/?>", stxt)
        if m !== nothing
            sxml, stagC, stagE = parseXMLTag(String(m.match))
            p += length(m.match)
            if !stagC
                sxml, _, stagE = parseXML(txt, sxml, p)
                p = stagE
            end
            append_tag!(xmlout, sxml)
            continue
        end

        m = match(r"^<([a-zA-Z0-9:]+)\s*/?>", stxt)
        if m !== nothing
            sxml, stagC, stagE = parseXMLTag(String(m.match))
            p += stagE
            if !stagC
                sxml, _, stagE = parseXML(txt, sxml, p)
                p = stagE
            end
            append_tag!(xmlout, sxml)
            continue
        end

        m = match(r"^[^<]+", txt[p:end])
        if m !== nothing
            text = strip(m.match)
            if haskey(xmlout, "__content")
                xmlout["__content"] *= " " * text
            else
                xmlout["__content"] = text
            end
            p += length(m.match)
            continue
        end

        if txt[p] == '<'
            p += 1
        end
    end

    return xmlout, tagC, p
end


function parseXMLTag(txt::String)
    xml = Dict{String, Any}()
    tagC = false

    tag_match = match(r"^<((?:[a-zA-Z0-9]+):)?([a-zA-Z0-9]+)\s*", txt)
    if tag_match === nothing
        error("Malformed tag: $txt")
    end

    if tag_match.captures[1] !== nothing
        xml["__prefix"] = tag_match.captures[1][1:end-1]  # drop ":"
    end
    xml["__name"] = tag_match.captures[2]
    p = tag_match.offset + length(tag_match.match)

    while p <= lastindex(txt)
        rest = txt[p:end]
        m = match(r"^([a-zA-Z0-9]+)\s*=\s*(\"([^\"]+)\"|'([^']+)')", rest)
        if m !== nothing
            attr_name = "_" * m.captures[1]
            attr_value = m.captures[3] !== nothing ? m.captures[3] : m.captures[4]
            xml[attr_name] = attr_value
            p += length(m.match)
            continue
        end

        if startswith(rest, "/>")
            tagC = true
            p += 2
            break
        elseif startswith(rest, ">")
            tagC = false
            p += 1
            break
        else
            p += 1  # skip invalid char
        end
    end

    return xml, tagC, p
end



function append_to_xmlout!(xmlout::Dict{String,Any}, sxml::Dict{String,Any})
    tag = sxml["__name"]
    if haskey(xmlout, tag)
        existing = xmlout[tag]
        if isa(existing, Vector)
            push!(existing, sxml)
        else
            xmlout[tag] = [existing, sxml]
        end
    else
        xmlout[tag] = sxml
    end
end

function append_tag!(xmlout::Dict{String, Any}, sxml::Dict{String, Any})
    tag = sxml["__name"]
    if haskey(xmlout, tag)
        existing = xmlout[tag]
        if isa(existing, Vector)
            push!(existing, sxml)
        else
            xmlout[tag] = [existing, sxml]
        end
    else
        xmlout[tag] = sxml
    end
end
