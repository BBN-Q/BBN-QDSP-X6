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
(0, 0, -1, -1, -1, -7, 3, 22, 5, -38, -9, 76, 40, -116, -79, 184, 166, -263,
-300, 399, 573, -660, -1200, 2201, 9158, 15165, 16851, 15629, 14858, 15430,
15921, 15626, 15297, 15448, 15665, 15595, 15457, 15486, 15566, 15558, 15516,
15517, 15536, 15539, 15534, 15534, 15534, 15534, 15534, 15534, 15534, 15534,
15534, 15534, 15534, 15534, 15534, 15534, 15534, 15534, 15534, 15534, 15534,
15534, 15534, 15534, 15534, 15534, 15534, 15534, 15534, 15534, 15534, 15534,
15534, 15534, 15534, 15534, 15534, 15534, 15534, 15534, 15534, 15534, 15534,
15534, 15534, 15534, 15534, 15534, 15534, 15534, 15534, 15534, 15534, 15534,
15534, 15534, 15534, 15534, 15534, 15540, 15530, 15512, 15529, 15571, 15543,
15457, 15494, 15649, 15612, 15349, 15368, 15796, 15833, 15135, 14961, 16193,
16733, 13333, 6375, 369, -1317, -95, 675, 104, -388, -93);

constant channel_filter_expected_im : integer_vector(0 to 127) :=
(-1, -1, 0, 0, 0, 2, -2, -8, -2, 12, 2, -26, -14, 39, 26, -63, -57, 88, 101,
-136, -195, 223, 406, -746, -3104, -5140, -5711, -5297, -5036, -5229, -5396,
-5296, -5184, -5235, -5309, -5285, -5239, -5248, -5275, -5273, -5259, -5259,
-5265, -5266, -5265, -5265, -5265, -5265, -5265, -5265, -5265, -5265, -5265,
-5265, -5265, -5265, -5265, -5265, -5265, -5265, -5265, -5265, -5265, -5265,
-5265, -5265, -5265, -5265, -5265, -5265, -5265, -5265, -5265, -5265, -5265,
-5265, -5265, -5265, -5265, -5265, -5265, -5265, -5265, -5265, -5265, -5265,
-5265, -5265, -5265, -5265, -5265, -5265, -5265, -5265, -5265, -5265, -5265,
-5265, -5265, -5265, -5265, -5267, -5263, -5257, -5263, -5277, -5268, -5239,
-5251, -5304, -5291, -5202, -5208, -5353, -5366, -5129, -5070, -5488, -5671,
-4519, -2161, -126, 446, 32, -229, -36, 131, 31);

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
