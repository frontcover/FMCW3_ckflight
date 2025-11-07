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
        config_done      : out std_logic;
        uart_txd         : out std_logic
    );
end config;

architecture Behavioral of config is

    component uart_tx is
    port(
        clk_40mhz    : in STD_LOGIC;
        reset_n      : in STD_LOGIC;
        uart_txd     : out STD_LOGIC; -- uart tx line
        
        data         : in STD_LOGIC_VECTOR(7 downto 0); -- data to be transferred over UART TX
        start_tx     : in STD_LOGIC;                
        tx_active    : out STD_LOGIC; -- 1 active, 0 not active
        tx_done      : out STD_LOGIC  -- 1 tx done, 0 not
    );
    end component;    
    

    -- State machine
    type config_state_type is (st_idle, st_read, st_wait, st_store, st_done);
    signal config_st : config_state_type := st_idle;
    
    type uart_state_type is (uart_idle, uart_start, uart_wait_done, uart_send_done);
    signal uart_st : uart_state_type := uart_idle;

    -- Counter and storage
    signal byte_counter         : integer range 0 to PACKET_SIZE-1 := 0;
    signal configuration_bytes  : std_logic_vector(PACKET_SIZE*8-1 downto 0) := (others => '0');    

    signal config_bytes_ready   : std_logic := '0';
    
    signal s_uart_data          : std_logic_vector(7 downto 0) := (others => '0');
    signal s_uart_start_tx      : std_logic := '0';
    signal s_uart_tx_active     : std_logic := '0';
    signal s_uart_tx_done       : std_logic := '0';    
    
    signal uart_send_index      : integer range 0 to PACKET_SIZE - 1 := 0;
    
begin
    
    uart_tx_i : uart_tx
    port map(
        clk_40mhz   => clk_40mhz,
        reset_n     => reset_n,
        uart_txd    => uart_txd,        
        data        => s_uart_data,
        start_tx    => s_uart_start_tx,                
        tx_active   => s_uart_tx_active,
        tx_done     => s_uart_tx_done
    );
    
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
    
    process(clk_40mhz, reset_n, soft_reset_n)
    begin
        if reset_n = '0' or soft_reset_n = '0' then
            s_uart_data <= (others => '0');
            s_uart_start_tx <= '0';
            uart_send_index <= 0;
            uart_st <= uart_idle;
            
        elsif rising_edge(clk_40mhz) then
            
            case uart_st is
            
                -- wait until config bytes are ready
                when uart_idle =>
                    
                    s_uart_start_tx <= '0';
                    
                    if config_bytes_ready = '1' then
                        uart_send_index <= 0;
                        s_uart_data <= configuration_bytes(7 downto 0);
                        s_uart_start_tx <= '1';
                        uart_st <= uart_start;    
                    
                    end if;
                
                -- clear start pulse one cycle
                when uart_start =>
                    s_uart_start_tx <= '0';
                    uart_st <= uart_wait_done;
                
                when uart_wait_done =>
                    if s_uart_tx_done = '1' then
                        if uart_send_index < PACKET_SIZE - 1 then
                            uart_send_index <= uart_send_index + 1;
                            s_uart_data <= configuration_bytes((uart_send_index+1)*8+7 downto (uart_send_index+1)*8);
                            s_uart_start_tx <= '1';
                            uart_st <= uart_start;                        
                        else
                            uart_st <= uart_send_done;    
                        
                        end if;                        
                    end if;
            
                when uart_send_done =>
                    
                    uart_st <= uart_send_done; -- reset or soft reset needed.
                
                when others =>
                    uart_st <= uart_idle;               
                
            end case;
        
        end if;    
    end process;

    
end Behavioral;
