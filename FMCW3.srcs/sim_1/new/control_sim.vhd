library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control_sim is
end control_sim;

architecture sim of control_sim is

    constant CLK_PERIOD : time := 10 ns;

    -- DUT signals
    signal clk        : std_logic := '0';
    signal reset      : std_logic := '1';
    signal muxout     : std_logic := '0';
    signal adc_data_a : std_logic_vector(15 downto 0) := (others => '0');
    signal adc_data_b : std_logic_vector(15 downto 0) := (others => '0');
    signal adc_valid  : std_logic := '0';
    signal adc_oe     : std_logic_vector(1 downto 0);
    signal adc_shdn   : std_logic_vector(1 downto 0);
    signal pa_en      : std_logic;
    signal config_done: std_logic := '0';
    signal usb_chipselect : std_logic;
    signal usb_write_n    : std_logic;
    signal usb_writedata  : std_logic_vector(7 downto 0);
    signal usb_tx_full    : std_logic := '0';

begin

    -- Instantiate DUT
    DUT: entity work.control
        port map (
            clk => clk,
            reset => reset,
            muxout => muxout,
            adc_data_a => adc_data_a,
            adc_data_b => adc_data_b,
            adc_valid => adc_valid,
            adc_oe => adc_oe,
            adc_shdn => adc_shdn,
            pa_en => pa_en,
            config_done => config_done,
            usb_chipselect => usb_chipselect,
            usb_write_n => usb_write_n,
            usb_writedata => usb_writedata,
            usb_tx_full => usb_tx_full
        );

    -- Clock generation
    clk_process: process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
    end process;

    -- Stimulus process
    stimulus: process
    begin
        -- Reset DUT
        reset <= '1';
        wait for 2*CLK_PERIOD;
        reset <= '0';
        wait for CLK_PERIOD;

        -- Enable config_done
        config_done <= '1';
        wait for CLK_PERIOD;

        -- Start ramp phase
        muxout <= '1';
        for i in 0 to 9 loop
            adc_data_a <= std_logic_vector(to_unsigned(i*10, 16));
            adc_data_b <= std_logic_vector(to_unsigned(i*20, 16));
            adc_valid  <= '1';
            wait for CLK_PERIOD;
        end loop;

        -- End ramp phase
        adc_valid <= '0';
        muxout <= '0';
        wait for 5*CLK_PERIOD;

        -- Wait for USB transfer to complete
        wait for 50*CLK_PERIOD;

        -- Finish simulation
        wait;
    end process;

end sim;
