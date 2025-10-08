library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity config_sim is
end config_sim;

architecture sim of config_sim is

    constant PACKET_SIZE : integer := 64;

    signal clk          : std_logic := '0';
    signal reset        : std_logic := '1';
    signal usb_rx_empty : std_logic := '1';  -- like RXF#: 1 = empty
    signal usb_readdata : std_logic_vector(7 downto 0) := (others => '0');
    signal chipselect   : std_logic;
    signal read_n       : std_logic;
    signal config_done  : std_logic;
    signal data_out     : std_logic_vector(PACKET_SIZE*8-1 downto 0);

    -- Local FTDI simulation variables
    type byte_array is array(0 to PACKET_SIZE-1) of std_logic_vector(7 downto 0);
    signal ftdi_data  : byte_array := (others => (others => '0'));
    signal data_index : integer := 0;

    --------------------------------------------------------------------
    -- DUT (Device Under Test) declaration
    --------------------------------------------------------------------
    component config
        generic (
            PACKET_SIZE : integer := 64
        );
        port (
            clk          : in  std_logic;
            reset        : in  std_logic;
            usb_rx_empty : in  std_logic;
            usb_readdata : in  std_logic_vector(7 downto 0);
            chipselect   : out std_logic;
            read_n       : out std_logic;
            config_done  : out std_logic;
            data_out     : out std_logic_vector(PACKET_SIZE*8-1 downto 0)
        );
    end component;

begin
    --------------------------------------------------------------------
    -- Instantiate DUT
    --------------------------------------------------------------------
    DUT: config
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

    --------------------------------------------------------------------
    -- Generate FTDI CLK (60 MHz typical)
    --------------------------------------------------------------------
    clk_proc: process
    begin
        while true loop
            clk <= '0';
            wait for 8.333 ns; -- 60 MHz period 16.667 ns
            clk <= '1';
            wait for 8.333 ns;
        end loop;
    end process;
    --------------------------------------------------------------------
    -- Stimulus process: emulate FT2232H synchronous FIFO
    --------------------------------------------------------------------
    ftdi_proc: process
    begin
        -- Reset phase
        wait for 50 ns;
        reset <= '0';
        wait for 50 ns;

        -- Fill FTDI data buffer
        for i in 0 to PACKET_SIZE-1 loop
            ftdi_data(i) <= std_logic_vector(to_unsigned(i, 8));
        end loop;
        data_index <= 0;

        -- Emulate data available
        usb_rx_empty <= '0'; -- usb_sync sends this flag to show rx is not empty

        while data_index < PACKET_SIZE loop
            
            wait until rising_edge(clk);
            
            -- drive read_n to read data from usb_sync
            if read_n = '0' then
            
                usb_readdata <= ftdi_data(data_index);
                data_index <= data_index + 1;
                
                -- All data is received so it can be emulated again that usb_syn has no data anymore
                if data_index = PACKET_SIZE then
                
                    usb_rx_empty <= '1'; -- FIFO empty
            
                end if;
            
            end if;
        
        end loop;

        wait for 100 ns;

        -- Verify config_done
        assert config_done = '1'
            report "Config not done after 64 bytes!" severity error;

        report "FT2232H simulation finished successfully!" severity note;
        wait;
    end process;

end sim;
