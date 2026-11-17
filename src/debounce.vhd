----------------------------------------------------------------------------------
-- Module Name:    debounce - Behavioral
-- Description:    Button debouncer. The output follows the input only after
--                 the input has been stable for CYCLES clock cycles.
--                 50 MHz clock, CYCLES = 500000 gives about 10 ms.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity debounce is
    Generic (
        CYCLES : integer := 500000
    );
    Port (
        clk  : in  STD_LOGIC;
        din  : in  STD_LOGIC;
        dout : out STD_LOGIC
    );
end debounce;

architecture Behavioral of debounce is

    signal sync0  : STD_LOGIC := '0';
    signal sync1  : STD_LOGIC := '0';
    signal stable : STD_LOGIC := '0';
    signal cnt    : integer range 0 to CYCLES := 0;

begin

    process (clk)
    begin
        if rising_edge(clk) then
            -- two-flop synchronizer
            sync0 <= din;
            sync1 <= sync0;

            if sync1 = stable then
                cnt <= 0;
            else
                if cnt = CYCLES - 1 then
                    stable <= sync1;
                    cnt    <= 0;
                else
                    cnt <= cnt + 1;
                end if;
            end if;
        end if;
    end process;

    dout <= stable;

end Behavioral;