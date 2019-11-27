"""
    Magic

`DataType` used for storing magic numbers, rook or bishop move masks, and respective shift and offset values for the computation of sliding moves.
"""
struct Magic
    mask::Bitboard
    num::Bitboard
    shift::Int32
    offset::Int32
end
Magic(mask::UInt64, num::UInt64, shift::Integer, offset::Integer) = Magic(Bitboard(mask), Bitboard(num), shift, offset)


const ROOK_MAGICS = @SVector [Magic(0x000101010101017e, 0x008000400020801a, 52, 0), Magic(0x000202020202027c, 0x0840004020001003, 53, 4096),
    Magic(0x000404040404047a, 0x8880200010018108, 53, 6144), Magic(0x0008080808080876, 0x0480040800801001, 53, 8192),
    Magic(0x001010101010106e, 0x0900080002050010, 53, 10240), Magic(0x002020202020205e, 0x0200100804010200, 53, 12288),
    Magic(0x004040404040403e, 0x0200010084080200, 53, 14336), Magic(0x008080808080807e, 0x0200024100821224, 52, 16384),
    Magic(0x0001010101017e00, 0x08a0802080004000, 53, 20480), Magic(0x0002020202027c00, 0x0006401004402000, 54, 22528),
    Magic(0x0004040404047a00, 0x0800802000100080, 54, 23552), Magic(0x0008080808087600, 0x4004800803100081, 54, 24576),
    Magic(0x0010101010106e00, 0x0106000810200600, 54, 25600), Magic(0x0020202020205e00, 0x2981000802040100, 54, 26624),
    Magic(0x0040404040403e00, 0x0004000804018210, 54, 27648), Magic(0x0080808080807e00, 0x0201000192026300, 53, 28672),
    Magic(0x00010101017e0100, 0x1038218000804000, 53, 30720), Magic(0x00020202027c0200, 0x1010004000200040, 54, 32768),
    Magic(0x00040404047a0400, 0x0108420012002881, 54, 33792), Magic(0x0008080808760800, 0x2098008008100080, 54, 34816),
    Magic(0x00101010106e1000, 0x4088010004090010, 54, 35840), Magic(0x00202020205e2000, 0x2000808002000400, 54, 36864),
    Magic(0x00404040403e4000, 0x028a0c0008021025, 54, 37888), Magic(0x00808080807e8000, 0x0000220000810064, 53, 38912),
    Magic(0x000101017e010100, 0x0040400480208000, 53, 40960), Magic(0x000202027c020200, 0x8040200040100042, 54, 43008),
    Magic(0x000404047a040400, 0x2000100080802000, 54, 44032), Magic(0x0008080876080800, 0x3090004040080401, 54, 45056),
    Magic(0x001010106e101000, 0x0100080080800400, 54, 46080), Magic(0x002020205e202000, 0x8230020080800400, 54, 47104),
    Magic(0x004040403e404000, 0x0002000200080104, 54, 48128), Magic(0x008080807e808000, 0x0c00010200004084, 53, 49152),
    Magic(0x0001017e01010100, 0x0000400082800020, 53, 51200), Magic(0x0002027c02020200, 0x0400200080804007, 54, 53248),
    Magic(0x0004047a04040400, 0x8400801000802001, 54, 54272), Magic(0x0008087608080800, 0x0018100080800800, 54, 55296),
    Magic(0x0010106e10101000, 0x0810310005004800, 54, 56320), Magic(0x0020205e20202000, 0x8000020080800400, 54, 57344),
    Magic(0x0040403e40404000, 0x2000302134000208, 54, 58368), Magic(0x0080807e80808000, 0x0000298402000645, 53, 59392),
    Magic(0x00017e0101010100, 0x0000800140018022, 53, 61440), Magic(0x00027c0202020200, 0x00184020100c4000, 54, 63488),
    Magic(0x00047a0404040400, 0x6210002804002000, 54, 64512), Magic(0x0008760808080800, 0x0001000c10010020, 54, 65536),
    Magic(0x00106e1010101000, 0x4201000800110004, 54, 66560), Magic(0x00205e2020202000, 0x2002000810020004, 54, 67584),
    Magic(0x00403e4040404000, 0xa40c21480a040090, 54, 68608), Magic(0x00807e8080808000, 0x0000004081020004, 53, 69632),
    Magic(0x007e010101010100, 0x3302410080002300, 53, 71680), Magic(0x007c020202020200, 0x9210002000401040, 54, 73728),
    Magic(0x007a040404040400, 0x0092110041200300, 54, 74752), Magic(0x0076080808080800, 0x0100100109002300, 54, 75776),
    Magic(0x006e101010101000, 0x000a800800240280, 54, 76800), Magic(0x005e202020202000, 0x0100040080020080, 54, 77824),
    Magic(0x003e404040404000, 0x0000506201080400, 54, 78848), Magic(0x007e808080808000, 0x1002209110440600, 53, 79872),
    Magic(0x7e01010101010100, 0x0140800300182241, 52, 81920), Magic(0x7c02020202020200, 0x8280184280220102, 53, 86016),
    Magic(0x7a04040404040400, 0x0005118042000a22, 53, 88064), Magic(0x7608080808080800, 0x008a000890204006, 53, 90112),
    Magic(0x6e10101010101000, 0x000200304844204a, 53, 92160), Magic(0x5e20202020202000, 0x108200080930041a, 53, 94208),
    Magic(0x3e40404040404000, 0x0482000100840842, 53, 96256), Magic(0x7e80808080808000, 0x0012192404430182, 52, 98304)]


const BISHOP_MAGICS = @SVector [Magic(0x0040201008040200, 0x4404700420508600, 58, 0), Magic(0x0000402010080400, 0x9120018401104008, 59, 64),
    Magic(0x0000004020100a00, 0x4004010401100084, 59, 96), Magic(0x0000000040221400, 0x0051040080062000, 59, 128),
    Magic(0x0000000002442800, 0x1124042010010092, 59, 160), Magic(0x0000000204085000, 0x1100882108001000, 59, 192),
    Magic(0x0000020408102000, 0x180a280248040000, 59, 224), Magic(0x0002040810204000, 0x0038440210900400, 58, 256),
    Magic(0x0020100804020000, 0x80074210e1010301, 59, 320), Magic(0x0040201008040000, 0x0020101012004e42, 59, 352),
    Magic(0x00004020100a0000, 0x8210100110411001, 59, 384), Magic(0x0000004022140000, 0x00008404108010a0, 59, 416),
    Magic(0x0000000244280000, 0x2060071040002804, 59, 448), Magic(0x0000020408500000, 0x6400020202211011, 59, 480),
    Magic(0x0002040810200000, 0x000c0d0111202000, 59, 512), Magic(0x0004081020400000, 0x8004050118020221, 59, 544),
    Magic(0x0010080402000200, 0x8005804088080910, 59, 576), Magic(0x0020100804000400, 0x6004a82001020200, 59, 608),
    Magic(0x004020100a000a00, 0x0101001004002041, 57, 640), Magic(0x0000402214001400, 0x8a1800a082004282, 57, 768),
    Magic(0x0000024428002800, 0x8806001012100098, 57, 896), Magic(0x0002040850005000, 0x0022810040504000, 57, 1024),
    Magic(0x0004081020002000, 0x4040800048480801, 59, 1152), Magic(0x0008102040004000, 0x0a42041304824120, 59, 1184),
    Magic(0x0008040200020400, 0x0204106085200814, 59, 1216), Magic(0x0010080400040800, 0x0890110682040111, 59, 1248),
    Magic(0x0020100a000a1000, 0x4000500001040080, 57, 1280), Magic(0x0040221400142200, 0x0000808018020102, 55, 1408),
    Magic(0x0002442800284400, 0x2401010010104008, 55, 1920), Magic(0x0004085000500800, 0x1052008004100080, 57, 2432),
    Magic(0x0008102000201000, 0x0000950104090801, 59, 2560), Magic(0x0010204000402000, 0x1200808000220864, 59, 2592),
    Magic(0x0004020002040800, 0x8188421201082050, 59, 2624), Magic(0x0008040004081000, 0x0035011001a05c00, 59, 2656),
    Magic(0x00100a000a102000, 0x0051480201104400, 57, 2688), Magic(0x0022140014224000, 0x4110040400180210, 55, 2816),
    Magic(0x0044280028440200, 0x0414140400001100, 55, 3328), Magic(0x0008500050080400, 0x4e60008100688040, 57, 3840),
    Magic(0x0010200020100800, 0x000121022ac40200, 59, 3968), Magic(0x0020400040201000, 0x00040042904a0094, 59, 4000),
    Magic(0x0002000204081000, 0x2948010421001040, 59, 4032), Magic(0x0004000408102000, 0x4060821011020200, 59, 4064),
    Magic(0x000a000a10204000, 0x0001004030008202, 57, 4096), Magic(0x0014001422400000, 0x0018020122080401, 57, 4224),
    Magic(0x0028002844020000, 0x0042ca41a2000400, 57, 4352), Magic(0x0050005008040200, 0x01c0212040810100, 57, 4480),
    Magic(0x0020002010080400, 0x1060480f41020041, 59, 4608), Magic(0x0040004020100800, 0x020102020a040040, 59, 4640),
    Magic(0x0000020408102000, 0x1082008220100402, 59, 4672), Magic(0x0000040810204000, 0x0102020202828102, 59, 4704),
    Magic(0x00000a1020400000, 0x4022108848080004, 59, 4736), Magic(0x0000142240000000, 0x0020400508480000, 59, 4768),
    Magic(0x0000284402000000, 0x1010108590440010, 59, 4800), Magic(0x0000500804020000, 0xd812040810a10140, 59, 4832),
    Magic(0x0000201008040200, 0x0191043000a20038, 59, 4864), Magic(0x0000402010080400, 0x8010020200620000, 59, 4896),
    Magic(0x0002040810204000, 0x0001008801084280, 58, 4928), Magic(0x0004081020400000, 0x0000060882015050, 59, 4992),
    Magic(0x000a102040000000, 0x8120000100809001, 59, 5024), Magic(0x0014224000000000, 0x0200100002104420, 59, 5056),
    Magic(0x0028440200000000, 0x10d100200821010a, 59, 5088), Magic(0x0050080402000000, 0x03002c0448100110, 59, 5120),
    Magic(0x0020100804020000, 0x14004005045c0042, 59, 5152), Magic(0x0040201008040200, 0x4002901008831040, 58, 5184)]

function subindex(occupied::Bitboard, magics::Magic)
    (((occupied & magics.mask).val * magics.num.val) >> magics.shift) + 1
end

# obtain the table index using the shift, occupancy mask, and magic number. Adding the offset.
function tableindex(occupied::Bitboard, magics::Magic)
    subindex(occupied, magics) + magics.offset
end

# generate all possible sliding moves in a given move direction, for a given occupancy.
function slidermoves(sqr::Bitboard, occupied::Bitboard, directions::SArray{Tuple{4},Function,1,4})
    mask = EMPTY
    for direction in directions
    	newsqr = sqr
		while !isempty(newsqr)
			newsqr = direction(newsqr)
    		mask ⊻= newsqr
    		!isempty(newsqr & occupied) && break
    	end
    end
    return mask
end

# initiate the attacks table for rook and bishop pieces
function initSlidingTable(table::Vector{Vector{Bitboard}}, magics::SArray{Tuple{64}, Magic, 1, 64}, directions::SArray{Tuple{4},Function,1,4})
	for sqr in 1:64
		occupied = EMPTY
		table[sqr] = Vector{Bitboard}(undef, 2^count(magics[sqr].mask))
		@inbounds for i in 1:(1 << count(magics[sqr].mask))
			idx = subindex(occupied, magics[sqr])
			table[sqr][idx] = slidermoves(Bitboard(sqr), occupied, directions)
			occupied = Bitboard(occupied.val - magics[sqr].mask.val) & magics[sqr].mask
		end
	end
	return table
end
