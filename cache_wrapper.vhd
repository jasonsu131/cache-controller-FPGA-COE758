----------------------------------------------------------------------------------
-- Module Name:    cache_wrapper - Structural
-- Description:    Figure 3 "Cache" box: cache_controller + cache_SRAM + muxes.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cache_wrapper is
    Port (
        clk       : in  STD_LOGIC;
        rst       : in  STD_LOGIC;

        -- CPU side
        cpu_addr  : in  STD_LOGIC_VECTOR (15 downto 0);
        cpu_wr_rd : in  STD_LOGIC;
        cpu_cs    : in  STD_LOGIC;
        cpu_dout  : in  STD_LOGIC_VECTOR (7 downto 0);   -- CPU write data
        cpu_din   : out STD_LOGIC_VECTOR (7 downto 0);   -- CPU read data
        cpu_rdy   : out STD_LOGIC;

        -- SDRAM controller side
        mem_addr  : out STD_LOGIC_VECTOR (15 downto 0);
        mem_wr_rd : out STD_LOGIC;
        mem_strb  : out STD_LOGIC;
        mem_din   : out STD_LOGIC_VECTOR (7 downto 0);   -- to SDRAM Din (writeback)
        mem_dout  : in  STD_LOGIC_VECTOR (7 downto 0)    -- from SDRAM Dout (fetch)
    );
end cache_wrapper;

architecture Structural of cache_wrapper is

    signal sram_addr    : STD_LOGIC_VECTOR (7 downto 0);
    signal sram_wen     : STD_LOGIC;
    signal sram_din     : STD_LOGIC_VECTOR (7 downto 0);
    signal sram_dout    : STD_LOGIC_VECTOR (7 downto 0);
    signal sel_sram_din : STD_LOGIC;
    signal sel_dout_mem : STD_LOGIC;

begin

    u_ctrl : entity work.cache_controller
        port map (
            clk          => clk,
            rst          => rst,
            cpu_addr     => cpu_addr,
            cpu_wr_rd    => cpu_wr_rd,
            cpu_cs       => cpu_cs,
            cpu_rdy      => cpu_rdy,
            mem_addr     => mem_addr,
            mem_wr_rd    => mem_wr_rd,
            mem_strb     => mem_strb,
            sram_addr    => sram_addr,
            sram_wen     => sram_wen,
            sel_sram_din => sel_sram_din,
            sel_dout_mem => sel_dout_mem
        );

    u_sram : entity work.cache_SRAM
        port map (
            clk  => clk,
            add  => sram_addr,
            wen  => sram_wen,
            din  => sram_din,
            dout => sram_dout
        );

    -- Mux at SRAM DIN: 0 = CPU DOUT (write hit), 1 = SDRAM DOUT (fetch)
    sram_din <= cpu_dout when sel_sram_din = '0' else mem_dout;

    -- Mux at SRAM DOUT: 0 = to CPU DIN (read hit), 1 = to SDRAM DIN (writeback)
    cpu_din <= sram_dout when sel_dout_mem = '0' else (others => '0');
    mem_din <= sram_dout when sel_dout_mem = '1' else (others => '0');

end Structural;