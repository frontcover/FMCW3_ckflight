library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_adc is
end tb_adc;

architecture sim of tb_adc is

    -- DUT signals
    signal clk        : std_logic := '0';
    signal adc_data   : std_logic_vector(11 downto 0) := (others => '0');
    signal data_a     : std_logic_vector(15 downto 0);
    signal data_b     : std_logic_vector(15 downto 0);
    signal valid      : std_logic;

    -- Clock period (40 MHz -> 25 ns)
    constant CLK_PERIOD : time := 25 ns;

begin

    -- Instantiate DUT
    uut: entity work.adc
        port map (
            clk      => clk,
            adc_data => adc_data,
            data_a   => data_a,
            data_b   => data_b,
            valid    => valid
        );

    ------------------------------------------------------------------------
    -- Clock generation
    ------------------------------------------------------------------------
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    ------------------------------------------------------------------------
    -- Stimulus generation
    ------------------------------------------------------------------------
    stim_process : process
    begin
        -- Apply ramp signal to ADC data
        for i in 0 to 4095 loop
            --adc_data <= std_logic_vector(to_unsigned(i mod 4096, 12));
            adc_data <= std_logic_vector(to_unsigned(i, 12));
            wait for CLK_PERIOD;
        end loop;

        wait;
    end process;

end sim;
