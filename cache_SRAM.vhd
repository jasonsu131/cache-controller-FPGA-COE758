----------------------------------------------------------------------------------
-- Module Name:    cache_SRAM - Behavioral
-- Description:    256 x 8 single-port RAM, stand-in for the Tutorial 3 BlockRAM.
--                 Synchronous write (WEN) and synchronous read: DOUT updates
--                 on the rising edge after ADD is applied (Figures 11 and 12).
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cache_SRAM is
    Port (
        clk  : in  STD_LOGIC;
        add  : in  STD_LOGIC_VECTOR (7 downto 0);
        wen  : in  STD_LOGIC;
        din  : in  STD_LOGIC_VECTOR (7 downto 0);
        dout : out STD_LOGIC_VECTOR (7 downto 0)
    );
end cache_SRAM;

architecture Behavioral of cache_SRAM is

    type ram_t is array (0 to 255) of std_logic_vector(7 downto 0);
    signal ram : ram_t := (others => (others => '0'));

begin

    process (clk)
    begin
        if rising_edge(clk) then
            if wen = '1' then
                ram(to_integer(unsigned(add))) <= din;
            end if;
            dout <= ram(to_integer(unsigned(add)));  -- read first
        end if;
    end process;

end Behavioral;