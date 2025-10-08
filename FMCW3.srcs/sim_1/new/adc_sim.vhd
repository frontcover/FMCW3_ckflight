library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use ieee.std_logic_textio.all;

entity adc_sim is
end adc_sim;

architecture sim of adc_sim is

    -- DUT component
    component adc
        Port( 
            clk         : in  STD_LOGIC;
            adc_data    : in  STD_LOGIC_VECTOR (11 downto 0);
            data_a      : out STD_LOGIC_VECTOR (15 downto 0);
            data_b      : out STD_LOGIC_VECTOR (15 downto 0);
            valid       : out STD_LOGIC
        );
    end component;

    -- Signals
    signal clk        : std_logic := '0';
    signal adc_data   : std_logic_vector(11 downto 0) := (others => '0');
    signal data_a     : std_logic_vector(15 downto 0);
    signal data_b     : std_logic_vector(15 downto 0);
    signal valid      : std_logic;

    constant clk_period : time := 25 ns;  -- 40 MHz

    -- File for logging
    file log_file : text open write_mode is "adc_output.txt";

begin

    ------------------------------------------------------------------
    -- Instantiate DUT
    ------------------------------------------------------------------
    uut : adc
        port map (
            clk       => clk,
            adc_data  => adc_data,
            data_a    => data_a,
            data_b    => data_b,
            valid     => valid
        );

    ------------------------------------------------------------------
    -- Clock generation
    ------------------------------------------------------------------
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process;

    ------------------------------------------------------------------
    -- Stimulus: continuous ramp input with wrap-around
    ------------------------------------------------------------------
    stim_proc : process
        variable i : integer := 0;
    begin
        loop  -- infinite loop
            adc_data <= std_logic_vector(to_unsigned(i, 12));
            wait for clk_period;

            -- Increment and wrap at 4096
            if i = 4095 then
                i := 0;
            else
                i := i + 1;
            end if;
        end loop;
    end process;

    ------------------------------------------------------------------
    -- Log both input and output
    ------------------------------------------------------------------
    write_proc : process(clk)
        variable L : line;
    begin
        if rising_edge(clk) then
            if valid = '1' then
                write(L, integer'image(to_integer(unsigned(adc_data))));
                write(L, string'(" "));
                write(L, integer'image(to_integer(signed(data_a))));
                write(L, string'(" "));
                write(L, integer'image(to_integer(signed(data_b))));
                writeline(log_file, L);
            end if;
        end if;
    end process;

end sim;
