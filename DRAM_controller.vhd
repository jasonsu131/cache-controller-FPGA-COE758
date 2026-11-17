----------------------------------------------------------------------------------
-- Module Name:    DRAM_controller - Behavioral
-- Description:    Behavioral main-memory model for COE758 Project 1.
--                 - Write: when memStrb = '1' and wr_rd = '1', Din is stored
--                   at Address on the rising clock edge (Figure 9).
--                 - Read:  Dout is registered from Address every clock, so it
--                   is valid one clock after the address is applied. The cache
--                   controller sets the address in phase 0 and strobes in
--                   phase 1, so Dout is valid during the strobe cycle (Figure 8).
--
--                 ADDR_BITS = 14 (16 KB) fits in the XC3S500E block RAM and
--                 covers every block CPU_gen touches without aliasing.
--                 Set ADDR_BITS to 16 for simulation if you want the full space.
--
--                 Memory powers up with mem(i) = low byte of i, so cold reads
--                 return known data.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DRAM_controller is
    Generic (
        ADDR_BITS : integer := 14
    );
    Port (
        clk     : in  STD_LOGIC;
        Address : in  STD_LOGIC_VECTOR(15 downto 0);
        wr_rd   : in  STD_LOGIC;
        memStrb : in  STD_LOGIC;
        Din     : in  STD_LOGIC_VECTOR(7 downto 0);
        Dout    : out STD_LOGIC_VECTOR(7 downto 0)
    );
end DRAM_controller;

architecture Behavioral of DRAM_controller is

    type mem_t is array (0 to (2**ADDR_BITS) - 1) of std_logic_vector(7 downto 0);

    function init_mem return mem_t is
        variable m : mem_t;
    begin
        for i in m'range loop
            m(i) := std_logic_vector(to_unsigned(i mod 256, 8));
        end loop;
        return m;
    end function;

    signal mem : mem_t := init_mem;

    signal addr_i : integer range 0 to (2**ADDR_BITS) - 1;

begin

    addr_i <= to_integer(unsigned(Address(ADDR_BITS - 1 downto 0)));

    p_dram_controller : process (clk)
    begin
        if rising_edge(clk) then
            if memStrb = '1' and wr_rd = '1' then
                mem(addr_i) <= Din;
            end if;
            Dout <= mem(addr_i);  -- registered read, every clock
        end if;
    end process p_dram_controller;

end Behavioral;