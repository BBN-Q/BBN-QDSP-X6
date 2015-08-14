using PyPlot
using Base.Test
include("vita.jl")

#Load the vita output file and reconstuct all the packets
vitaDict = VitaStreamDict("../../FPGA/II-X6/II-X6.sim/sim_1/behav/vitastream.out")

rawRecs = map(x -> convert(Vector{Int16}, x), vitaDict[0x0100])
numRecs = length(rawRecs)

demodRecs1 = map(x -> convert(Vector{Complex{Int16}}, x), vitaDict[0x0110])
demodRecs2 = map(x -> convert(Vector{Complex{Int16}}, x), vitaDict[0x0120])

rawKIRecs1 = map(x -> convert(Complex{Int32}, x), vitaDict[0x0101])
rawKIRecs2 = map(x -> convert(Complex{Int32}, x), vitaDict[0x0102])

step = floor(2^16/320)
rawKernel = collect(-2^15:step:-2^15+319*step) + 1im*collect(2^15-1:-step:2^15-1-319*step)

for ct = 1:numRecs
  expected = (sum(rawKernel .* 5awRecs[ct][1:320])) / 2^13
  @test rawKIRecs1[ct] == floor(real(expected)) + 1im*floor(imag(expected))
end

demodKIRecs1 = map(x -> convert(Complex{Int32}, x), vitaDict[0x0111])
demodKIRecs2 = map(x -> convert(Complex{Int32}, x), vitaDict[0x0121])

step = floor(2^16/160)
demodKernel = collect(-2^15:step:-2^15+159*step) + 1im*collect(2^15-1:-step:2^15-1-159*step)

for ct = 1:numRecs
  expected = (sum(demodKernel .* demodRecs1[ct][1:160])) / 2^10
  @test demodKIRecs1[ct] == floor(real(expected)) + 1im*floor(imag(expected))
end

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
xlabel("Frequency (MHz)")
