function subIndex(occupied::UInt64, magic::UInt64, moveMask::UInt64)
	(((occupied & moveMask) * magic) >> (64 - count_ones(moveMask))) + 1
end

function tableIndex(occupied::UInt64, magic::UInt64, moveMask::UInt64, offset::Int)
	subIndex(occupied, magic, moveMask) + offset
end

function sliderMoves(sqr::UInt64, occupied::UInt64, moveDirections::SArray{Tuple{4},Function,1,4})
	moveMask = zero(UInt)
	for direction in moveDirections
		newSqr = sqr
		while newSqr > zero(UInt)
			newSqr = direction(newSqr)
			moveMask ⊻= newSqr
			(newSqr & occupied > zero(UInt)) && break
		end
	end
	return moveMask
end

function initSlidingTable(table::Vector{UInt}, magics::SArray{Tuple{64},UInt64,1,64}, moveMasks::SArray{Tuple{64},UInt64,1,64}, offset::SArray{Tuple{64},Int64,1,64}, moveDirections::SArray{Tuple{4},Function,1,4})
	for sqr in 1:64
		occupied = zero(UInt)
		@inbounds for i in 1:(1 << count_ones(moveMasks[sqr]))
			idx = tableIndex(occupied, magics[sqr], moveMasks[sqr], offset[sqr])
			table[idx] = sliderMoves(getBitboard(sqr), occupied, moveDirections)
			occupied = (occupied - moveMasks[sqr]) & moveMasks[sqr]
		end
	end
	return table
end
