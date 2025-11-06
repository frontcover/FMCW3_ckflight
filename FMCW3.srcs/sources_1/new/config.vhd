library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity config is
    generic (
        PACKET_SIZE : integer := 128
    );
    port (
        clk_40mhz        : in  std_logic;
        clk_100mhz       : in  std_logic;
        reset_n          : in  std_logic; -- active low
        soft_reset_n     : in  std_logic;     
        usb_rx_empty     : in  std_logic;
        usb_readdata     : in  std_logic_vector(7 downto 0);
        chipselect       : out std_logic;
        read_n           : out std_logic;
        config_done      : out std_logic
    );
end config;

architecture Behavioral of config is

    -- State machine
    type config_state_type is (st_idle, st_read, st_wait, st_store, st_done);
    signal config_st : config_state_type := st_idle;
    
    type fifo_state_type is (st_idle, st_send, st_done);
    signal fifo_st : fifo_state_type := st_idle;

    -- Counter and storage
    signal byte_counter                 : integer range 0 to PACKET_SIZE-1 := 0;
    signal configuration_bytes          : std_logic_vector(PACKET_SIZE*8-1 downto 0) := (others => '0');    

    signal config_bytes_ready : std_logic := '0';
    
begin
    
    process(clk_40mhz, reset_n, soft_reset_n)
    begin
        
        -- Instead of handshaking microlbaze issues a soft reset to reset config and control so it starts again for new radar op
        if reset_n = '0' or soft_reset_n = '0' then
            config_st                   <= st_idle;
            byte_counter                <= 0;
            configuration_bytes         <= (others => '0');
            chipselect                  <= '0'; -- 1 active, 0 not
            read_n                      <= '1'; -- 0 active, 1 not
            config_done                 <= '0'; -- not done
            config_bytes_ready          <= '0'; 
        elsif rising_edge(clk_40mhz) then
            
            case config_st is

                when st_idle =>
                    
                    config_done  <= '0';
                    chipselect   <= '1';
                    read_n       <= '1';
                    
                    if usb_rx_empty = '0' then
                        config_st <= st_read;
                    end if;

                when st_read =>
                    read_n <= '0';   -- assert read for one clock
                    config_st <= st_wait;

                when st_wait =>
                    read_n <= '1';   -- deassert read
                    config_st <= st_store;  -- now data is valid next clock

                when st_store =>
                    
                    -- store valid byte
                    configuration_bytes((byte_counter*8+7) downto (byte_counter*8)) <= usb_readdata;

                    if byte_counter = PACKET_SIZE-1 then                        
                        config_st <= st_done;
                    else
                        byte_counter <= byte_counter + 1;
                                                
                        if usb_rx_empty = '0' then
                            config_st <= st_read;
                        else
                            config_st <= st_idle;  -- wait until data available again
                        end if;
                    end if;
                
                when st_done =>                                        
                    byte_counter <= 0;
                    chipselect  <= '0';
                    read_n      <= '1';
                    config_done <= '1';
                    config_bytes_ready <= '1';
                    config_st <= st_done; -- from here the received packet will be sent
                    
                when others =>
                    config_st <= st_idle;

            end case;
        end if;
    end process;

    
end Behavioral;
