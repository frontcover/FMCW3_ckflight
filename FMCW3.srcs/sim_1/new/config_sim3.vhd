library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity config_sim3 is
end config_sim3;

architecture sim of config_sim3 is

    constant PACKET_SIZE : integer := 8;  -- shorter for visibility

    -- DUT signals
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '1';
    signal soft_reset   : std_logic := '1';
    signal usb_rx_empty : std_logic := '1';
    signal usb_readdata : std_logic_vector(7 downto 0) := (others => '0');
    signal chipselect   : std_logic;
    signal read_n       : std_logic;
    signal config_done  : std_logic;
    signal data_out     : std_logic_vector(PACKET_SIZE*8-1 downto 0);
    
    type byte_array is array(0 to PACKET_SIZE-1) of std_logic_vector(7 downto 0);
    signal ftdi_data  : byte_array := (others => (others => '0'));

begin

    ----------------------------------------------------------------
    -- DUT instantiation
    ----------------------------------------------------------------
    DUT: entity work.config
        generic map (
            PACKET_SIZE => PACKET_SIZE
        )
        port map (
            clk          => clk,
            reset        => reset,
            soft_reset   => soft_reset,
            usb_rx_empty => usb_rx_empty,
            usb_readdata => usb_readdata,
            chipselect   => chipselect,
            read_n       => read_n,
            config_done  => config_done,
            data_out     => data_out
        );

    ----------------------------------------------------------------
    -- 60 MHz clock
    ----------------------------------------------------------------
    clk_proc: process
    begin
        while true loop
            clk <= '0';
            wait for 8.333 ns;
            clk <= '1';
            wait for 8.333 ns;
        end loop;
    end process;

    ----------------------------------------------------------------
    -- STIMULUS PROCESS (with local procedure)
    ----------------------------------------------------------------
    stimulus: process

        procedure simulate_python_transfer is
            variable data_index : integer := 0;
        begin
            
            -- Fill test packet with sequential data
            for i in 0 to PACKET_SIZE-1 loop
                ftdi_data(i) <= std_logic_vector(to_unsigned(i, 8));
                wait for 10 ns;
            end loop;

            -- Simulate intermittent USB data bursts
            usb_rx_empty <= '0'; -- not empty there is data 
            for i in 0 to PACKET_SIZE-1 loop
                wait until read_n = '0';      -- wait until DUT actually requests data
                usb_readdata <= ftdi_data(i); -- provide next byte
                wait until read_n = '1';      -- wait until read completes before next
            end loop;
            usb_rx_empty <= '1'; -- empty

            wait for 100 ns;
            
        end procedure;

    begin
        ----------------------------------------------------------------
        -- INITIAL RESET
        ----------------------------------------------------------------
        report "Simulation started - applying global reset";
        reset <= '0';
        wait for 50 ns;
        reset <= '1';
        wait for 50 ns;

        report "Reset released - config module ready";

        ----------------------------------------------------------------
        -- FIRST CONFIG TRANSFER
        ----------------------------------------------------------------
        simulate_python_transfer;
        wait for 100 ns;

        ----------------------------------------------------------------
        -- SOFT RESET 1
        ----------------------------------------------------------------
        report "Applying soft reset...";
        soft_reset <= '0';
        wait for 50 ns;
        soft_reset <= '1';
        report "Soft reset released";

        wait for 100 ns;
        simulate_python_transfer;
        wait for 100 ns;

        ----------------------------------------------------------------
        -- SOFT RESET 2
        ----------------------------------------------------------------
        report "Applying second soft reset...";
        soft_reset <= '0';
        wait for 50 ns;
        soft_reset <= '1';
        report "Soft reset released again";

        wait for 100 ns;
        simulate_python_transfer;
        wait for 100 ns;
        
        reset <= '0';
        wait for 50 ns;
        reset <= '1';
        wait for 50 ns;

        simulate_python_transfer;
    
        ----------------------------------------------------------------
        -- END OF TEST
        ----------------------------------------------------------------
        wait for 200 ns;
        report "All transfers and soft resets completed successfully!" severity note;
        wait;
    end process;

end sim;
