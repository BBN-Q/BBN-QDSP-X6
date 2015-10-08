using PyPlot
using Base.Test
include("vita.jl")

#Load the vita output file and reconstuct all the packets
vitaDict = VitaStreamDict("../../FPGA/II-X6/II-X6.sim/sim_1/behav/vitastream.out")

rawRecs = map(x -> convert(Vector{Int16}, x), vitaDict[0x0100])
numRecs = length(rawRecs)

demodRecs1 = map(x -> convert(Vector{Complex{Int16}}, x), vitaDict[0x0110])
@test length(demodRecs1) == numRecs
demodRecs2 = map(x -> convert(Vector{Complex{Int16}}, x), vitaDict[0x0120])
@test length(demodRecs2) == numRecs

rawKIRecs1 = map(x -> convert(Complex{Int32}, x), vitaDict[0x0101])
@test length(rawKIRecs1) == numRecs
rawKIRecs2 = map(x -> convert(Complex{Int32}, x), vitaDict[0x0102])
@test length(rawKIRecs2) == numRecs

step = floor(2^16/320)
rawKernel = collect(-2^15:step:-2^15+319*step) + 1im*collect(2^15-1:-step:2^15-1-319*step)

for ct = 1:numRecs
  expected = (sum(rawKernel .* rawRecs[ct][1:320])) / 2^13
  @test rawKIRecs1[ct] == floor(real(expected)) + 1im*floor(imag(expected))
end

b1 = vec(readdlm("ip/FIR_ChannelSelect_Stage1.coe", ',', '\n', skipstart=2))
b2 = vec(readdlm("ip/FIR_ChannelSelect_Stage2.coe", ',', '\n', skipstart=2))

dds1 = exp(-1im*2pi*10e6*4e-9*(3:1282)) #delay to start after DDS valid
for ct in 1:numRecs
    mult = dds1 .* (rawRecs[ct] / (1 << 13))
    stage1 = filt(b1, 1, mult)[4:4:end]
    stage2 = filt(b2, 1, stage1)[2:2:end]
    @test_approx_eq_eps stage2 (demodRecs1[ct] / (1 << 14))  1e-3
    if ct == 11
        figure()
        plot(real(demodRecs1[11]) / (1 << 14))
        plot(real(stage2[1:end]))
        xlabel("Decimated Samples")
        title("Demodulated Signal at NCO Frequency")
    end
end


demodKIRecs1 = map(x -> convert(Complex{Int32}, x), vitaDict[0x0111])
@test length(demodKIRecs1) == numRecs
demodKIRecs2 = map(x -> convert(Complex{Int32}, x), vitaDict[0x0121])
@test length(demodKIRecs2) == numRecs

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
  refSpec = exp(-1im*2pi*(freqs[ct]-30)*1e6*demodTimeStep*(1:demodRecLength))
  magSpec2[ct] = abs(sum(refSpec.*demodRecs2[ct]))/demodRecLength
end

figure()
plot(freqs, magSpec1)
plot(freqs, magSpec2)
xlabel("Frequency (MHz)")
title("Channelizer Magnitude Response")
