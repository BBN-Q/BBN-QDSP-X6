using PyPlot

include("vita.jl")

#Load the vita output file and reconstuct all the packets
vitaDict = VitaStreamDict("../../FPGA/II-X6/II-X6.sim/sim_1/behav/vitastream.out")

rawRecs = map(x -> convert(Vector{Int16}, x), vitaDict[0x0100])

demodRecs1 = map(x -> convert(Vector{Complex{Int16}}, x), vitaDict[0x0110])
demodRecs2 = map(x -> convert(Vector{Complex{Int16}}, x), vitaDict[0x0120])


numRecs = length(demodRecs1)
demodRecLength = length(demodRecs1[1])
demodTimeStep = 1e-9*32
freqs = collect(0:numRecs-1)
magSpec1 = zeros(numRecs)
magSpec2 = zeros(numRecs)
for ct = 1:numRecs
  refSpec = exp(-1im*2pi*(freqs[ct]-10)*1e6*demodTimeStep*(1:demodRecLength))
  magSpec1[ct] = abs(sum(refSpec.*demodRecs1[ct]))/demodRecLength
  refSpec = exp(-1im*2pi*(freqs[ct]-20)*1e6*demodTimeStep*(1:demodRecLength))
  magSpec2[ct] = abs(sum(refSpec.*demodRecs2[ct]))/demodRecLength
end

plot(freqs, magSpec1)
plot(freqs, magSpec2)
