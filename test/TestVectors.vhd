library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package TestVectors is

--Generated in Julia with
-- b1 = vec(readdlm("ip/FIR_ChannelSelect_Stage1.coe", ',', '\n', skipstart=2))
-- b2 = vec(readdlm("ip/FIR_ChannelSelect_Stage2.coe", ',', '\n', skipstart=2))
-- data_in = (2^13-1)*[exp(1im*2pi*13e6*4e-9*(0:767)); zeros(Float64, 256)]
-- dds = (2^15-1)*exp(-1im*2pi*13e6*4e-9*(1:1024))
-- mult = dds .* data_in
-- stage1 = filt(b1, 1.0, mult)[1:4:end]
-- stage2 = filt(b2, 1.0, stage1)[1:2:end]
-- stage2_re = floor(Int, real(stage2) / 128 * 2 / 256)
-- stage2_im = floor(Int, imag(stage2) / 128 * 2 / 256)

type integer_vector is array(natural range <>) of integer;  --already defined in VHDL-2008

constant channel_filter_expected_re : integer_vector(0 to 127) :=
(0, -1, -1, -1, 1, -2, -17, -5, 38, 3, -95, -8, 180, -7, -343, 41, 625, -197,
-1338, 1188, 8242, 14913, 16805, 15503, 14887, 15542, 15817, 15449, 15322,
15524, 15578, 15476, 15456, 15500, 15506, 15491, 15490, 15491, 15491, 15491,
15491, 15491, 15491, 15491, 15491, 15491, 15491, 15491, 15491, 15491, 15491,
15491, 15491, 15491, 15491, 15491, 15491, 15491, 15491, 15491, 15491, 15491,
15491, 15491, 15491, 15491, 15491, 15491, 15491, 15491, 15491, 15491, 15491,
15491, 15491, 15491, 15491, 15491, 15491, 15491, 15491, 15491, 15491, 15491,
15491, 15491, 15491, 15491, 15491, 15491, 15491, 15491, 15491, 15491, 15491,
15491, 15491, 15491, 15491, 15491, 15489, 15492, 15508, 15496, 15453, 15488,
15585, 15499, 15310, 15497, 15833, 15449, 14865, 15688, 16828, 14303, 7248, 578,
-1314, -13, 604, -51, -327, 42, 169, -33, -88, 14);

constant channel_filter_expected_im : integer_vector(0 to 127) :=
(-1, 0, 0, 0, -1, 0, 5, 1, -14, -2, 31, 2, -62, 2, 115, -15, -213, 66, 453,
-403, -2794, -5054, -5695, -5254, -5045, -5267, -5361, -5236, -5193, -5261,
-5280, -5245, -5238, -5253, -5255, -5250, -5250, -5250, -5250, -5250, -5250,
-5250, -5250, -5250, -5250, -5250, -5250, -5250, -5250, -5250, -5250, -5250,
-5250, -5250, -5250, -5250, -5250, -5250, -5250, -5250, -5250, -5250, -5250,
-5250, -5250, -5250, -5250, -5250, -5250, -5250, -5250, -5250, -5250, -5250,
-5250, -5250, -5250, -5250, -5250, -5250, -5250, -5250, -5250, -5250, -5250,
-5250, -5250, -5250, -5250, -5250, -5250, -5250, -5250, -5250, -5250, -5250,
-5250, -5250, -5250, -5250, -5250, -5251, -5256, -5252, -5237, -5249, -5282,
-5253, -5189, -5252, -5366, -5236, -5038, -5317, -5703, -4847, -2457, -196, 445,
4, -205, 17, 110, -15, -58, 11, 29, -5);

type KERNEL_ARRAY_t is array(natural range <>) of std_logic_vector(31 downto 0);
function create_ramp_kernel(num_points : natural) return KERNEL_ARRAY_t;

end TestVectors;

package body TestVectors is

--Create a ramp from MAX_NEG to MAX_POS real and flipped imaginary kernel
function create_ramp_kernel(num_points : natural) return KERNEL_ARRAY_t is
variable kernel_array : KERNEL_ARRAY_t(0 to num_points-1);
constant STEP : natural := (2**16)/num_points;
begin
  for ct in 0 to num_points-1 loop
    kernel_array(ct) := std_logic_vector(to_signed(2**15 - 1 - STEP*ct, 16)) &
                        std_logic_vector(to_signed(-2**15 + STEP*ct, 16));
  end loop;
  return kernel_array;
end create_ramp_kernel;


end package body;
