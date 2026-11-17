----------------------------------------------------------------------------------
-- Module Name:    cache_controller - Behavioral
-- Description:    COE758 Project 1 cache controller.
--                 8 blocks x 32 bytes, direct mapped, write-back.
--                 Address: Tag[15:8] Index[7:5] Offset[4:0]
--
--                 Tags, valid and dirty bits live here. The data bytes live in
--                 cache_SRAM, addressed by (index & offset).
--
--                 Block transfers use 2 clocks per word:
--                   phase 0: set address / WR_RD
--                   phase 1: assert MEMSTRB for one clock (Figures 8 and 9)
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity cache_controller is
    Port (
        clk          : in  STD_LOGIC;
        rst          : in  STD_LOGIC;

        -- CPU side
        cpu_addr     : in  STD_LOGIC_VECTOR (15 downto 0);
        cpu_wr_rd    : in  STD_LOGIC;
        cpu_cs       : in  STD_LOGIC;
        cpu_rdy      : out STD_LOGIC;

        -- SDRAM controller side
        mem_addr     : out STD_LOGIC_VECTOR (15 downto 0);
        mem_wr_rd    : out STD_LOGIC;
        mem_strb     : out STD_LOGIC;

        -- Cache SRAM side
        sram_addr    : out STD_LOGIC_VECTOR (7 downto 0);
        sram_wen     : out STD_LOGIC;

        -- Mux selects (Figure 3)
        sel_sram_din : out STD_LOGIC;  -- 0 = CPU DOUT, 1 = SDRAM DOUT
        sel_dout_mem : out STD_LOGIC   -- 0 = SRAM DOUT to CPU DIN, 1 = to SDRAM DIN
    );
end cache_controller;

architecture Behavioral of cache_controller is

    -- Cache block status
    type tag_array is array (0 to 7) of std_logic_vector(7 downto 0);
    type bit_array is array (0 to 7) of std_logic;
    signal tags       : tag_array := (others => (others => '0'));
    signal valid_bits : bit_array := (others => '0');
    signal dirty_bits : bit_array := (others => '0');

    -- Address Word Register (AWR) and latched request type
    signal awr_tag    : std_logic_vector(7 downto 0) := (others => '0');
    signal awr_index  : std_logic_vector(2 downto 0) := (others => '0');
    signal awr_offset : std_logic_vector(4 downto 0) := (others => '0');
    signal wr_rd_reg  : std_logic := '0';

    -- FSM
    type state_type is (IDLE, CHECK, READ_HIT, WRITE_HIT, WRITEBACK, FETCH, COMPLETE);
    signal state      : state_type := IDLE;
    signal next_state : state_type;

    -- Block transfer control
    signal cnt   : unsigned(4 downto 0) := (others => '0');
    signal phase : std_logic := '0';

    -- CS rising-edge detection (CS is held for 4 clocks)
    signal cs_d     : std_logic := '0';
    signal cs_start : std_logic;

    -- Hit/miss info
    signal index_i   : integer range 0 to 7;
    signal hit       : std_logic;
    signal cur_dirty : std_logic;

begin

    cs_start  <= cpu_cs and (not cs_d);
    index_i   <= to_integer(unsigned(awr_index));
    hit       <= '1' when (valid_bits(index_i) = '1' and tags(index_i) = awr_tag) else '0';
    cur_dirty <= dirty_bits(index_i);

    ------------------------------------------------------------------
    -- State register, AWR latch, block counter, tag/valid/dirty update
    ------------------------------------------------------------------
    p_seq : process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state      <= IDLE;
                cs_d       <= '0';
                cnt        <= (others => '0');
                phase      <= '0';
                valid_bits <= (others => '0');
                dirty_bits <= (others => '0');
            else
                state <= next_state;
                cs_d  <= cpu_cs;

                -- Latch the request when a new transaction starts
                if state = IDLE and cs_start = '1' then
                    awr_tag    <= cpu_addr(15 downto 8);
                    awr_index  <= cpu_addr(7 downto 5);
                    awr_offset <= cpu_addr(4 downto 0);
                    wr_rd_reg  <= cpu_wr_rd;
                end if;

                -- Word counter / phase for block transfers
                if state = WRITEBACK or state = FETCH then
                    phase <= not phase;
                    if phase = '1' then
                        cnt <= cnt + 1;  -- wraps 31 -> 0 on its own
                    end if;
                else
                    phase <= '0';
                    cnt   <= (others => '0');
                end if;

                -- Status updates on a write hit
                if state = WRITE_HIT then
                    valid_bits(index_i) <= '1';
                    dirty_bits(index_i) <= '1';
                end if;

                -- Status updates when the fetched block is complete
                if state = FETCH and phase = '1' and cnt = 31 then
                    tags(index_i)       <= awr_tag;
                    valid_bits(index_i) <= '1';
                    dirty_bits(index_i) <= '0';
                end if;
            end if;
        end if;
    end process p_seq;

    ------------------------------------------------------------------
    -- Next-state logic
    ------------------------------------------------------------------
    p_next : process (state, cs_start, hit, cur_dirty, wr_rd_reg, cnt, phase)
    begin
        next_state <= state;

        case state is

            when IDLE =>
                if cs_start = '1' then
                    next_state <= CHECK;
                end if;

            when CHECK =>
                if hit = '1' then
                    if wr_rd_reg = '1' then
                        next_state <= WRITE_HIT;
                    else
                        next_state <= READ_HIT;
                    end if;
                else
                    if cur_dirty = '1' then
                        next_state <= WRITEBACK;
                    else
                        next_state <= FETCH;
                    end if;
                end if;

            when READ_HIT =>
                next_state <= COMPLETE;

            when WRITE_HIT =>
                next_state <= COMPLETE;

            when WRITEBACK =>
                if phase = '1' and cnt = 31 then
                    next_state <= FETCH;
                end if;

            when FETCH =>
                if phase = '1' and cnt = 31 then
                    if wr_rd_reg = '1' then
                        next_state <= WRITE_HIT;
                    else
                        next_state <= READ_HIT;
                    end if;
                end if;

            when COMPLETE =>
                next_state <= IDLE;

        end case;
    end process p_next;

    ------------------------------------------------------------------
    -- Output logic
    ------------------------------------------------------------------
    p_out : process (state, cs_start, awr_tag, awr_index, awr_offset, cnt, phase, tags, index_i)
    begin
        -- Defaults
        cpu_rdy      <= '0';
        mem_strb     <= '0';
        mem_wr_rd    <= '0';
        sram_wen     <= '0';
        sel_sram_din <= '0';
        sel_dout_mem <= '0';
        mem_addr     <= awr_tag & awr_index & "00000";
        sram_addr    <= awr_index & awr_offset;

        case state is

            when IDLE =>
                cpu_rdy <= not cs_start;  -- drop RDY as soon as a request arrives

            when CHECK =>
                null;

            when READ_HIT =>
                null;  -- SRAM address is applied; DOUT is valid in COMPLETE

            when WRITE_HIT =>
                sram_wen <= '1';

            when WRITEBACK =>
                -- Write the old block to [old tag & index & word]
                sram_addr    <= awr_index & std_logic_vector(cnt);
                mem_addr     <= tags(index_i) & awr_index & std_logic_vector(cnt);
                mem_wr_rd    <= '1';
                sel_dout_mem <= '1';
                mem_strb     <= phase;

            when FETCH =>
                -- Read the new block from [new tag & index & word] into the SRAM
                sram_addr    <= awr_index & std_logic_vector(cnt);
                mem_addr     <= awr_tag & awr_index & std_logic_vector(cnt);
                mem_wr_rd    <= '0';
                sel_sram_din <= '1';
                mem_strb     <= phase;
                sram_wen     <= phase;

            when COMPLETE =>
                cpu_rdy <= '1';

        end case;
    end process p_out;

end Behavioral;