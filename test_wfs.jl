WF_LENGTH = 1024;

freqs = 10;

wf0 = [zeros(Int16, 256), int16(2^11*sin(2*pi*(20/1000)*[0:511])), zeros(Int16, 256)]
wf1 = [zeros(Int16, 256), int16(2^11*sin(pi + 2*pi*(20/1000)*[0:511])), zeros(Int16, 256)]


fid = open("testWFs.in", "w")
writedlm(fid, wf0', ' ')
writedlm(fid, wf1', ' ')
close(fid)
