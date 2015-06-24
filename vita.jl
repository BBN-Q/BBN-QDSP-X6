typealias VitaPacket Vector{UInt32}
typealias VitaStreamDict Dict{Uint16, Vector{VitaPacket}}

import Base.convert

#Stream ID lives in the bottom 16 bits of the second word
streamID(packet::VitaPacket) = UInt16(packet[2] & 0xffff)

padding_bytes(packet::VitaPacket) = UInt8((packet[end] & 0x0f00) >> 8)

#Strip 7 header words and 1 tail
payload(packet::VitaPacket) = packet[8:end-1]

function convert(::Type{Vector{Int16}}, packet::VitaPacket)
	#16bit words are packed as
	#	W1	W0
	#	W3	W2
	#	W5	W4
	data = Array(Int16, 2*(length(packet)-8))
	for (ct,word) in enumerate(payload(packet))
		data[2*ct-1] = (word & 0xffff) % Int16
		data[2*ct] = ((word & 0xffff0000) >> 16) % Int16
	end
	data
end

function convert(::Type{Vector{Complex{Int16}}}, packet::VitaPacket)
	data = Array(Complex{Int16}, (length(packet)-8))
	for (ct,word) in enumerate(payload(packet))
		data[ct] = 1im*(((word & 0xffff0000) >> 16) % Int16)  + (word & 0xffff) % Int16;
	end
	data
end

function accumulate(packets::Vector{VitaPacket}, recordLength::Int, numSegments::Int)
	#Accumulate vita packets in a approriately sized buffer
	if ((streamID(packets[1]) & 0xf0) == 0)
		tStream = Vector{Int16}
		tAccum = Int
	else
		tStream = Vector{Complex{Int16}}
		tAccum = Complex{Int}
	end

	buf = zeros(tAccum, recordLength, numSegments)
	idx = 1
	for p in packets
		for d in convert(tStream, p)
			buf[idx] += d
			idx += 1
			if idx > length(buf)
				idx = 1
			end
		end
	end
	buf
end

function accumulate_raw(packets::Vector{VitaPacket}, recordLength, numSegments)
end

function VitaStreamDict(fileName::String)
	#Turn a simulation output file of 32 bit words into a dictionary of packets
	vitaDict = VitaStreamDict() #scope for the do block below; TODO: potentially use default dict

	open(fileName, "r") do FID
		rawData = map(ln -> parse(UInt32, rstrip(ln), 16), readlines(FID))

		#Peak at the packet header to pull out the length and stream ID
		idx = 1
		while (idx < length(rawData))
			pktLength = rawData[idx] & 0xffff
			pktID = UInt16(rawData[idx+1] & 0xffff)
			if (!haskey(vitaDict, pktID))
				vitaDict[pktID] = VitaPacket[]
			end
			push!(vitaDict[pktID], rawData[idx:idx+pktLength-1])
			idx += pktLength
		end
	end
	vitaDict
end
