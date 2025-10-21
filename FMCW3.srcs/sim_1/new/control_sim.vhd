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
    signal microblaze_sampling_done : std_logic := '0';
    signal control_done : std_logic := '0';

begin

    -------------------------------------------------------------------------
    -- DUT INSTANTIATION
    -------------------------------------------------------------------------
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
            usb_tx_full => usb_tx_full,
            microblaze_sampling_done => microblaze_sampling_done,
            control_done => control_done 
        );

    -------------------------------------------------------------------------
    -- CLOCK GENERATION
    -------------------------------------------------------------------------
    clk_process: process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
    end process;

    -------------------------------------------------------------------------
    -- STIMULUS PROCESS
    -------------------------------------------------------------------------
    stimulus: process
    begin
        ---------------------------------------------------------------------
        -- PHASE 1: RESET AND CONFIGURATION
        ---------------------------------------------------------------------
        report "Simulation started - resetting DUT";
        reset <= '1';
        wait for 2*CLK_PERIOD;
        reset <= '0';
        report "Reset released";

        wait for 5*CLK_PERIOD;
        config_done <= '1';
        report "Configuration done signal set HIGH";

        ---------------------------------------------------------------------
        -- PHASE 2: ACTIVE SAMPLING PHASE
        ---------------------------------------------------------------------
        muxout <= '1';
        report "MUXOUT HIGH - Sampling started";

        for i in 0 to 15 loop
            adc_data_a <= std_logic_vector(to_unsigned(i*10, 16));
            adc_data_b <= std_logic_vector(to_unsigned(i*20, 16));
            adc_valid  <= '1';
            wait for CLK_PERIOD;
        end loop;

        adc_data_a <= std_logic_vector(to_unsigned(0, 16));
        adc_data_b <= std_logic_vector(to_unsigned(0, 16));
            
        adc_valid <= '0';
        muxout <= '0';
        report "Sampling phase complete, waiting for MicroBlaze command";

        ---------------------------------------------------------------------
        -- PHASE 3: MICRO-BLAZE STOPS SAMPLING
        ---------------------------------------------------------------------
        wait for 20*CLK_PERIOD;
        microblaze_sampling_done <= '1';
        report "MicroBlaze signals sampling done";

        wait for 5*CLK_PERIOD;
        microblaze_sampling_done <= '0'; -- short pulse, just a handshake
        report "MicroBlaze done pulse cleared";

        ---------------------------------------------------------------------
        -- PHASE 4: CONTROL MODULE SHOULD RESPOND WITH CONTROL_DONE
        ---------------------------------------------------------------------
        wait until control_done = '1';
        report "CONTROL_DONE detected - control process completed";

        ---------------------------------------------------------------------
        -- PHASE 5: END OF SIMULATION
        ---------------------------------------------------------------------
        wait for 10*CLK_PERIOD;
        report "Simulation finished successfully";
        wait;
    end process;

end sim;
