library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_adc is
end tb_adc;

architecture sim of tb_adc is

    -- DUT signals
    signal clk       : std_logic := '0';
    signal adc_data  : std_logic_vector(11 downto 0) := (others => '0');
    signal data_a    : std_logic_vector(15 downto 0);
    signal data_b    : std_logic_vector(15 downto 0);
    signal valid     : std_logic;

    -- ADC increment counters
    signal cnt_a : unsigned(11 downto 0) := (others => '0');

begin

    -- Instantiate the DUT
    dut: entity work.adc
    port map (
        clk       => clk,
        adc_data  => adc_data,
        data_a    => data_a,
        data_b    => data_b,
        valid     => valid
    );

    -- Clock generation: 40 MHz
    clk_process: process
    begin
        while now < 100 us loop
            clk <= '0';
            wait for 12.5 ns;
            clk <= '1';
            wait for 12.5 ns;
        end loop;
        wait;
    end process;

    -- Generate incrementing ADC data
    adc_proc: process(clk)
    begin
        if rising_edge(clk) then
            -- Increment counter
            cnt_a <= cnt_a + 1;
            -- Feed it as ADC input
            adc_data <= std_logic_vector(cnt_a);
        end if;
    end process;

    -- Optional: monitor output
    monitor_proc: process(clk)
    begin
        if rising_edge(clk) then
            if valid = '1' then
                report "Output valid: data_a=" & integer'image(to_integer(unsigned(data_a))) &
                       " data_b=" & integer'image(to_integer(unsigned(data_b)));
            end if;
        end if;
    end process;

end sim;
