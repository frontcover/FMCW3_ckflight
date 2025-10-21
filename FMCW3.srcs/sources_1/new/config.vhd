library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity config is
    generic (
        PACKET_SIZE : integer := 128
    );
    port (
        clk          : in  std_logic;
        reset        : in  std_logic;        
        usb_rx_empty : in  std_logic;
        usb_readdata : in  std_logic_vector(7 downto 0);
        chipselect   : out std_logic;
        read_n       : out std_logic;
        config_done  : out std_logic;
        data_out     : out std_logic_vector(PACKET_SIZE*8-1 downto 0);
        control_done : in std_logic     -- will be used to reset config logic so it can restart listening python
    );
end config;

architecture Behavioral of config is

    -- State machine
    type state_type is (st_idle, st_read, st_wait, st_store, st_done);
    signal st : state_type := st_idle;

    -- Counter and storage
    signal byte_counter : integer range 0 to PACKET_SIZE := 0;
    signal tmp_data     : std_logic_vector(PACKET_SIZE*8-1 downto 0) := (others => '0');

begin

    process(clk, reset)
    begin
        
        -- if reset or control modules sampling is done then config can start listening to python again
        -- control done means; whole sampling for N seconds is done. User selects amount of second to run radar.
        if reset = '1' or control_done = '1' then
            st           <= st_idle;
            byte_counter <= 0;
            tmp_data     <= (others => '0');
            chipselect   <= '0'; -- 1 active, 0 not
            read_n       <= '1'; -- 0 active, 1 not
            config_done  <= '0'; -- not done

        elsif rising_edge(clk) then
            
            case st is

                when st_idle =>
                    
                    config_done  <= '0';
                    chipselect   <= '1';
                    read_n       <= '1';
                    
                    if usb_rx_empty = '0' then
                        st <= st_read;
                    end if;

                when st_read =>
                    read_n <= '0';   -- assert read for one clock
                    st <= st_wait;

                when st_wait =>
                    read_n <= '1';   -- deassert read
                    st <= st_store;  -- now data is valid next clock

                when st_store =>
                    
                    -- store valid byte
                    tmp_data((byte_counter*8+7) downto (byte_counter*8)) <= usb_readdata;

                    if byte_counter = PACKET_SIZE-1 then                        
                        st <= st_done;
                    else
                        byte_counter <= byte_counter + 1;
                                                
                        if usb_rx_empty = '0' then
                            st <= st_read;
                        else
                            st <= st_idle;  -- wait until data available again
                        end if;
                    end if;
                
                when st_done =>                                        
                    byte_counter <= 0;
                    chipselect  <= '0';
                    read_n      <= '1';
                    config_done <= '1';

                    st <= st_done; -- from here the received packet will be sent
                    
                when others =>
                    st <= st_idle;

            end case;
        end if;
    end process;

    data_out <= tmp_data;

end Behavioral;
