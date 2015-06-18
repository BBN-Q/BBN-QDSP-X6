library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package TestVectors is

--Generated in Julia with
-- b1 = map(Float64,  readdlm("ip/FIR_ChannelSelect_Stage1.coe",   ',  ',   '\n',   skipstart=2)[:,  1])
-- b2 = map(Float64,  readdlm("ip/FIR_ChannelSelect_Stage2.coe",   ',  ',   '\n',   skipstart=2)[:,  1])
-- data_in = (2^13-1)*[zeros(Float64,   128); exp(1im*2pi*13e6*4e-9*(0:767)); zeros(Float64,   128)]
-- dds = (2^15-1)*exp(-1im*2pi*13e6*4e-9*(1:1024))
-- mult = dds .* data_in
-- stage1 = filt(b1, 1.0, mult)[1:4:end]
-- stage2 = filt(b2, 1.0, stage1)[1:2:end]
-- stage2_re = floor(Int, real(stage2) / 128 * 2 / 256)
-- stage2_im = floor(Int, imag(stage2) / 128 * 2 / 256)

type integer_vector is array(natural range <>) of integer;  --already defined in VHDL-2008

constant channel_filter_expected_re : integer_vector(0 to 127) :=
(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, 0, 33, 44, -54,
-107, 142, 341, -413, -2251, -3998, -4597, -4344, -4132, -4208, -4294, -4274,
-4245, -4245, -4245, -4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246,
-4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246,
-4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246,
-4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246,
-4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246,
-4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246,
-4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246, -4246,
-4246, -4245, -4245, -4246, -4279, -4290, -4192, -4139, -4388, -4587, -3833,
-1995, -248, 351, 98);

constant channel_filter_expected_im : integer_vector(0 to 127) :=
(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -125, -164,
199, 395, -529, -1263, 1527, 8329, 14796, 17010, 16075, 15289, 15572, 15889,
15817, 15710, 15710, 15710, 15711, 15711, 15711, 15711, 15711, 15711, 15711,
15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711,
15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711,
15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711,
15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711,
15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711,
15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711, 15711,
15711, 15711, 15710, 15710, 15711, 15836, 15874, 15511, 15315, 16239, 16973,
14183, 7381, 915, -1300, -365);

type KERNEL_ARRAY_t is array(natural range <>) of std_logic_vector(31 downto 0);
function create_ramp_kernel(num_points : natural) return KERNEL_ARRAY_t;

end TestVectors;

package body TestVectors is

--Create a ramp from MAX_NEG to MAX_POS real and flipped imaginary kernel
function create_ramp_kernel(num_points : natural) return KERNEL_ARRAY_t is
variable kernel_array : KERNEL_ARRAY_t(0 to num_points-1);
constant STEP : natural := 65536/num_points;
begin
  for ct in 0 to num_points-1 loop
    kernel_array(ct) := std_logic_vector(to_signed(-65536 + STEP*ct, 16)) &
                        std_logic_vector(to_signed(65535 - STEP*ct, 16));
  end loop;
  return kernel_array;
end create_ramp_kernel;


end package body;
