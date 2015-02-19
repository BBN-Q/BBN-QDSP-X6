WF_LENGTH = 1024;

wf0 = vcat(round(Int16, 2^11*0.9*sin(2*pi*(10/1000)*(0:511))), zeros(Int16, 508), Int16[0x00ba, 0x00ad, 0x00f0, 0x000f])
wf1 = vcat(round(Int16, 2^11*0.9*sin(2*pi*(10/1000)*(0:511))), zeros(Int16, 508), Int16[0x00ba, 0x00ad, 0x00f0, 0x000f])

open("testWFs.in", "w") do fid
	for ct in 1:10
		writedlm(fid, wf0', ' ')
		writedlm(fid, wf1', ' ')
	end
end
