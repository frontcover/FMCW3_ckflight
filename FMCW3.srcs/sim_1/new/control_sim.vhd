library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control_sim is
end control_sim;

architecture sim of control_sim is

    constant CLK_PERIOD : time := 10 ns;

    signal clk                      : std_logic := '0';
    signal reset                    : std_logic := '1';
    signal soft_reset               : std_logic := '1';
    signal muxout                   : std_logic := '0';
    signal adc_data_a               : std_logic_vector(15 downto 0) := (others => '0');
    signal adc_data_b               : std_logic_vector(15 downto 0) := (others => '0');
    signal adc_valid                : std_logic := '0';
    signal adc_oe                   : std_logic_vector(1 downto 0);
    signal adc_shdn                 : std_logic_vector(1 downto 0);
    signal pa_en                    : std_logic;
    signal config_done              : std_logic := '0';
    signal usb_chipselect           : std_logic;
    signal usb_write_n              : std_logic;
    signal usb_writedata            : std_logic_vector(7 downto 0);
    signal usb_tx_full              : std_logic := '0';
    signal microblaze_sampling_done : std_logic := '0';
    signal ramp_done                : std_logic := '0';

begin

    DUT: entity work.control
        port map (
            clk                      => clk,
            reset                    => reset,
            soft_reset               => soft_reset,
            muxout                   => muxout,
            adc_data_a               => adc_data_a,
            adc_data_b               => adc_data_b,
            adc_valid                => adc_valid,
            adc_oe                   => adc_oe,
            adc_shdn                 => adc_shdn,
            pa_en                    => pa_en,
            config_done              => config_done,
            usb_chipselect           => usb_chipselect,
            usb_write_n              => usb_write_n,
            usb_writedata            => usb_writedata,
            usb_tx_full              => usb_tx_full,
            microblaze_sampling_done => microblaze_sampling_done,
            ramp_done                => ramp_done
        );

    clk_process: process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
    end process;

    stimulus: process
        procedure simulate_ramp(ramp_id : integer) is
        begin
            muxout <= '1';
            report "RAMP " & integer'image(ramp_id) & " STARTED";
            for i in 0 to 15 loop
                adc_data_a <= std_logic_vector(to_unsigned(i*10, 16));
                adc_data_b <= std_logic_vector(to_unsigned(i*20, 16));
                adc_valid  <= '1';
                wait for CLK_PERIOD;
            end loop;
            adc_valid <= '0';
            muxout <= '0';
            report "RAMP " & integer'image(ramp_id) & " ENDED";
            wait for 180 * CLK_PERIOD;
        end procedure;
    begin
        report "Simulation started - resetting DUT";
        reset <= '0';
        wait for 3 * CLK_PERIOD;
        reset <= '1';
        wait for 5 * CLK_PERIOD;
        config_done <= '1';
        report "Reset released, config_done set";

        wait for 10 * CLK_PERIOD;

        for n in 1 to 5 loop
            simulate_ramp(n);
        end loop;

        report "MicroBlaze signals DONE after 5 ramps";
        microblaze_sampling_done <= '1';
        wait for 100 * CLK_PERIOD;
        microblaze_sampling_done <= '0';
        
        report "Soft reset triggered";
        soft_reset <= '0';
        wait for 100 * CLK_PERIOD;
        soft_reset <= '1';
        
        -- I have tested both clearing microblaze done before or after software reset
        --wait for 1000 * CLK_PERIOD;
        --microblaze_sampling_done <= '0';
        
        report "Soft reset released, FSM restarted";

        wait for 50 * CLK_PERIOD;

        for n in 6 to 10 loop
            simulate_ramp(n);
        end loop;

        report "MicroBlaze signals DONE after 10 total ramps";
        microblaze_sampling_done <= '1';

        wait for 100 * CLK_PERIOD;
        report "Simulation finished successfully";
        wait;
    end process;

end sim;
