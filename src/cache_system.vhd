----------------------------------------------------------------------------------
-- Module Name:    cache_system - Structural
-- Description:    COE758 Project 1 top level (Figure 3) with ChipScope ILA,
--                 and a debounced trigger button.
--                 CPU_gen -> cache_wrapper <-> DRAM_controller
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity cache_system is
    Port (
        clk  : in  STD_LOGIC;
        rst  : in  STD_LOGIC;
        trig : in  STD_LOGIC   -- push button: start next CPU transaction
    );
end cache_system;

architecture Structural of cache_system is

    -- ChipScope cores
    component ICON
        port (
            CONTROL0 : inout STD_LOGIC_VECTOR (35 downto 0)
        );
    end component;

    component ILA
        port (
            CONTROL : inout STD_LOGIC_VECTOR (35 downto 0);
            CLK     : in    STD_LOGIC;
            DATA    : in    STD_LOGIC_VECTOR (31 downto 0);
            TRIG0   : in    STD_LOGIC_VECTOR (7 downto 0)
        );
    end component;

    signal control0 : STD_LOGIC_VECTOR (35 downto 0);
    signal ila_data : STD_LOGIC_VECTOR (31 downto 0);
    signal ila_trig : STD_LOGIC_VECTOR (7 downto 0);

    -- Debounced trigger button
    signal trig_db  : STD_LOGIC;

    -- CPU <-> cache
    signal cpu_addr  : STD_LOGIC_VECTOR (15 downto 0);
    signal cpu_wr_rd : STD_LOGIC;
    signal cpu_cs    : STD_LOGIC;
    signal cpu_dout  : STD_LOGIC_VECTOR (7 downto 0);
    signal cpu_din   : STD_LOGIC_VECTOR (7 downto 0);
    signal cpu_rdy   : STD_LOGIC;

    -- cache <-> SDRAM controller
    signal mem_addr  : STD_LOGIC_VECTOR (15 downto 0);
    signal mem_wr_rd : STD_LOGIC;
    signal mem_strb  : STD_LOGIC;
    signal mem_dout  : STD_LOGIC_VECTOR (7 downto 0);
    signal mem_din   : STD_LOGIC_VECTOR (7 downto 0);

begin

    u_debounce : entity work.debounce
        generic map (
            CYCLES => 500000
        )
        port map (
            clk  => clk,
            din  => trig,
            dout => trig_db
        );

    u_cpu : entity work.CPU_gen
        port map (
            clk     => clk,
            rst     => rst,
            trig    => trig_db,
            Address => cpu_addr,
            wr_rd   => cpu_wr_rd,
            cs      => cpu_cs,
            DOut    => cpu_dout
        );

    u_cache : entity work.cache_wrapper
        port map (
            clk       => clk,
            rst       => rst,
            cpu_addr  => cpu_addr,
            cpu_wr_rd => cpu_wr_rd,
            cpu_cs    => cpu_cs,
            cpu_dout  => cpu_dout,
            cpu_din   => cpu_din,
            cpu_rdy   => cpu_rdy,
            mem_addr  => mem_addr,
            mem_wr_rd => mem_wr_rd,
            mem_strb  => mem_strb,
            mem_din   => mem_din,
            mem_dout  => mem_dout
        );

    u_dram : entity work.DRAM_controller
        port map (
            clk     => clk,
            Address => mem_addr,
            wr_rd   => mem_wr_rd,
            memStrb => mem_strb,
            Din     => mem_din,
            Dout    => mem_dout
        );

    ------------------------------------------------------------------
    -- ChipScope probes
    ------------------------------------------------------------------
    ila_data(15 downto 0)  <= cpu_addr;
    ila_data(23 downto 16) <= cpu_din;
    ila_data(24)           <= cpu_wr_rd;
    ila_data(25)           <= cpu_cs;
    ila_data(26)           <= cpu_rdy;
    ila_data(27)           <= mem_wr_rd;
    ila_data(28)           <= mem_strb;
    ila_data(31 downto 29) <= "000";

    ila_trig(0)            <= cpu_cs;
    ila_trig(1)            <= cpu_wr_rd;
    ila_trig(2)            <= cpu_rdy;
    ila_trig(3)            <= mem_strb;
    ila_trig(4)            <= mem_wr_rd;
    ila_trig(7 downto 5)   <= "000";

    u_icon : ICON
        port map (
            CONTROL0 => control0
        );

    u_ila : ILA
        port map (
            CONTROL => control0,
            CLK     => clk,
            DATA    => ila_data,
            TRIG0   => ila_trig
        );

end Structural;