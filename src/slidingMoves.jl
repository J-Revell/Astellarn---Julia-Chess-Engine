# obtain the table index using the shift, occupancy mask, and magic number. (ignoring offset)
function subIndex(occupied::UInt64, magics::Magic)
	(((occupied & magics.mask) * magics.num) >> magics.shift) + one(Int)
end

# obtain the table index using the shift, occupancy mask, and magic number. Adding the offset.
function tableIndex(occupied::UInt64, magics::Magic)
	subIndex(occupied, magics) + magics.offset
end

# generate all possible sliding moves in a given move direction, for a given occupancy.
function sliderMoves(sqr_bb::UInt64, occupied::UInt64, moveDirections::SArray{Tuple{4},Function,1,4})
	moveMask = zero(UInt)
	for direction in moveDirections
		newSqr = sqr_bb
		while newSqr > zero(UInt)
			newSqr = direction(newSqr)
			moveMask ⊻= newSqr
			(newSqr & occupied > zero(UInt)) && break
		end
	end
	return moveMask
end

# generate the sliding tables, by creating the indexes and all possible occupancy masks.
# function initSlidingTable(table::Vector{UInt}, magics::SArray{Tuple{64}, Magic, 1, 64}, moveDirections::SArray{Tuple{4},Function,1,4})
# 	for sqr in 1:64
# 		occupied = zero(UInt)
# 		@inbounds for i in 1:(1 << count_ones(magics[sqr].mask))
# 			idx = tableIndex(occupied, magics[sqr])
# 			table[idx] = sliderMoves(getBitboard(sqr), occupied, moveDirections)
# 			occupied = (occupied - magics[sqr].mask) & magics[sqr].mask
# 		end
# 	end
# 	return table
# end

function initSlidingTable(table::Vector{Vector{UInt}}, magics::SArray{Tuple{64}, Magic, 1, 64}, moveDirections::SArray{Tuple{4},Function,1,4})
	for sqr in 1:64
		occupied = zero(UInt)
		table[sqr] = Vector{UInt}(undef, 2^count_ones(magics[sqr].mask))
		@inbounds for i in 1:(1 << count_ones(magics[sqr].mask))
			idx = subIndex(occupied, magics[sqr])
			table[sqr][idx] = sliderMoves(getBitboard(sqr), occupied, moveDirections)
			occupied = (occupied - magics[sqr].mask) & magics[sqr].mask
		end
	end
	return table
end
