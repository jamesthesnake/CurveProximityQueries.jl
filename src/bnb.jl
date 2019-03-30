function _init(a, b::RectifiableCurve{D, T}) where {D, T}
    leaves = PriorityQueue{Interval{T}, T}()
    glb, gub = getbounds(a, b, b.limits)
    soln = b.limits
    leaves[soln] = glb
    return leaves, glb, gub, soln
end

function _init(a::RectifiableCurve{D, T}, b::RectifiableCurve{D, T}) where {D, T}
    leaves = PriorityQueue{IntervalBox{2, T}, T}()
    glb, gub = getbounds(a, b, a.limits, b.limits)
    soln = IntervalBox(a.limits, b.limits)
    leaves[soln] = glb
    return leaves, glb, gub, soln
end

function _init(b::RectifiableCurve, a)
    return _init(a, b)
end

function _loop(a, b, leaves, glb, gub)
    leaf = dequeue!(leaves)

    left, right = bisect(leaf)

    lb, ub = getbounds(a, b, left...)
    lb = lb > glb ? lb : glb
    gub = gub > ub ? ub : gub
    leaves[left] = lb

    lb, ub = getbounds(a, b, right...)
    lb = lb > glb ? lb : glb
    gub = gub > ub ? ub : gub
    leaves[right] = lb

    soln, glb = peek(leaves)
    return glb, gub, soln
end

function _loop(b::RectifiableCurve, a, leaves, glb, gub)
    return _loop(a, b, leaves, glb, gub)
end

function _loop(a::RectifiableCurve, b::RectifiableCurve, leaves, glb, gub)
    leaf = dequeue!(leaves)

    left, right = bisect(leaf)

    lb, ub = getbounds(a, b, left...)
    lb = lb > glb ? lb : glb
    gub = gub > ub ? ub : gub
    leaves[left] = lb

    lb, ub = getbounds(a, b, right...)
    lb = lb > glb ? lb : glb
    gub = gub > ub ? ub : gub
    leaves[right] = lb

    soln, glb = peek(leaves)
    return glb, gub, soln
end

function closest_points(a, b; atol=1e-8)
    leaves, glb, gub, soln = _init(a, b)
    while (gub - glb) > atol
        glb, gub, soln = _loop(a, b, leaves, glb, gub)
    end
    return closest_points(a, b, soln)
end

function closest_points(a, b::RectifiableCurve{D}, soln) where {D}
    evalb = b(mid(soln))
    return ConvexBodyProximityQueries.closest_points(a, evalb, @SVector(ones(D)))
end

function closest_points(b::RectifiableCurve{D}, a, soln) where {D}
    closest_points(a, b, soln)
end

function closest_points(a::RectifiableCurve{D}, b::RectifiableCurve{D}, soln) where {D}
    evala = a(mid(soln[1]))
    evalb = b(mid(soln[2]))
    return ConvexBodyProximityQueries.closest_points(evala, evalb, @SVector(ones(D)))
end

function minimum_distance(a, b; atol=1e-8)
    leaves, glb, gub, soln = _init(a, b)
    while (gub - glb) > atol
        glb, gub, soln = _loop(a, b, leaves, glb, gub)
    end
    return glb
end

function tolerance_verification(a, b, Δ::Real; atol=1e-8)
    leaves, glb, gub, soln = _init(a, b)
    while (gub - Δ) > atol
        glb, gub, soln = _loop(a, b, leaves, glb, gub)
        if glb > Δ
            return true
        end
    end
    return false
end

function collision_detection(a, b; atol=1e-8)
    leaves, glb, gub, soln = _init(a, b)
    while gub > atol
        glb, gub, soln = _loop(a, b, leaves, glb, gub)
        if glb > 0
            return false
        end
    end
    return true
end