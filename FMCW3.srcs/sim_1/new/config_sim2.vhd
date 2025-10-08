library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity config_sim is
end config_sim;

architecture sim of config_sim is

    constant PACKET_SIZE : integer := 16;  -- shorter for easy viewing

    signal clk          : std_logic := '0';
    signal reset        : std_logic := '1';
    signal usb_rx_empty : std_logic := '1';
    signal usb_readdata : std_logic_vector(7 downto 0) := (others => '0');
    signal chipselect   : std_logic;
    signal read_n       : std_logic;
    signal config_done  : std_logic;
    signal data_out     : std_logic_vector(PACKET_SIZE*8-1 downto 0);

    type byte_array is array(0 to PACKET_SIZE-1) of std_logic_vector(7 downto 0);
    signal ftdi_data : byte_array := (others => (others => '0'));
    signal data_index : integer := 0;

    ----------------------------------------------------------------
    -- DUT
    ----------------------------------------------------------------
    component config
        generic (
            PACKET_SIZE : integer := 16
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

    DUT: config
        generic map (PACKET_SIZE => PACKET_SIZE)
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
    -- 60 MHz clock (typical FT2232H)
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
    -- FTDI-like behavior
    ----------------------------------------------------------------
    ftdi_proc: process
    begin
        -- Reset
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        -- Fill data
        for i in 0 to PACKET_SIZE-1 loop
            ftdi_data(i) <= std_logic_vector(to_unsigned(i, 8));
        end loop;

        usb_rx_empty <= '0';
        wait for 50 ns;

        while data_index < PACKET_SIZE loop
            wait until rising_edge(clk);

            -- when FPGA asserts read_n low, present next byte
            if read_n = '0' then
                usb_readdata <= ftdi_data(data_index);
                data_index <= data_index + 1;

                -- simulate intermittent empty condition
                if (data_index mod 4) = 0 then
                    usb_rx_empty <= '1'; -- pause for a while
                    wait for 100 ns;
                    usb_rx_empty <= '0'; -- data available again
                end if;
            end if;
        end loop;

        usb_rx_empty <= '1';
        wait for 200 ns;

        assert config_done = '1'
            report "Config not done after all bytes!" severity error;

        report "FT2232H simulation finished successfully!" severity note;
        wait;
    end process;

end sim;
