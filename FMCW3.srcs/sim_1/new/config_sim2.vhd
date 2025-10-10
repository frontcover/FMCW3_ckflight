library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity config_sim2 is
end config_sim2;


-- This simulation tries to mimic reception that does not happen in a periodic order.
-- to see how state machine of the config behaves when data does not come for a while etc.

architecture sim of config_sim2 is

    constant PACKET_SIZE : integer := 8;  -- shorter for visibility in simulation

    -- Signals for DUT
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '1';
    signal usb_rx_empty : std_logic := '1';
    signal usb_readdata : std_logic_vector(7 downto 0) := (others => '0');
    signal chipselect   : std_logic;
    signal read_n       : std_logic;
    signal config_done  : std_logic;
    signal data_out     : std_logic_vector(PACKET_SIZE*8-1 downto 0);

    -- Local FTDI simulation array
    type byte_array is array(0 to PACKET_SIZE-1) of std_logic_vector(7 downto 0);
    signal ftdi_data  : byte_array := (others => (others => '0'));
    signal data_index : integer := 0;

begin

    ----------------------------------------------------------------
    -- Instantiate DUT
    ----------------------------------------------------------------
    DUT: entity work.config
        generic map (
            PACKET_SIZE => PACKET_SIZE
        )
        port map (
            clk          => clk,
            reset        => reset,
            usb_rx_empty => usb_rx_empty,
            usb_readdata => usb_readdata,
            chipselect   => chipselect,
            read_n       => read_n,
            config_done  => config_done,
            data_out     => data_out
        );

    ----------------------------------------------------------------
    -- Generate 60 MHz clock
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
    -- FTDI-like data source with bursts and pauses
    ----------------------------------------------------------------
    ftdi_proc: process
    begin
        -- Initial reset
        wait for 50 ns;
        reset <= '0';
        wait for 50 ns;

        -- Fill FTDI buffer with sequential data
        for i in 0 to PACKET_SIZE-1 loop
            ftdi_data(i) <= std_logic_vector(to_unsigned(i, 8));
        end loop;
        data_index <= 0;

        -- Start: FIFO empty
        usb_rx_empty <= '1';
        wait for 100 ns;

        -- === First burst: 5 bytes ===
        usb_rx_empty <= '0'; -- usb_sync says data has arrived so fifo not empty, can be read
        
        for i in 0 to 2 loop
            wait until rising_edge(clk);
            if read_n = '0' then
                usb_readdata <= ftdi_data(data_index);
                data_index <= data_index + 1;
            end if;
        end loop;

        -- Pause: FIFO empty
        usb_rx_empty <= '1';
        wait for 100 ns;

        -- === Second burst: 6 bytes ===
        usb_rx_empty <= '0';
        for i in 0 to 5 loop
            wait until rising_edge(clk);
            if read_n = '0' then
                usb_readdata <= ftdi_data(data_index);
                data_index <= data_index + 1;
            end if;
        end loop;

        -- Pause again
        usb_rx_empty <= '1';
        wait for 80 ns;

        -- === Final burst: remaining bytes ===
        usb_rx_empty <= '0';
        while data_index < PACKET_SIZE loop
            wait until rising_edge(clk);
            if read_n = '0' then
                usb_readdata <= ftdi_data(data_index);
                data_index <= data_index + 1;
            end if;
        end loop;

        -- FIFO empty after all bytes sent
        usb_rx_empty <= '1';
        wait for 50 ns;

        -- Check if config_done asserted
        assert config_done = '1'
            report "Config not done after all bytes!" severity error;

        report "Intermittent USB simulation finished successfully!" severity note;
        wait;
    end process;

end sim;
