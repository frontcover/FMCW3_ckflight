library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_tx is
    GENERIC(
        CLOCK_NUMBER : integer := 347 -- 40mhz clock 115200 baudrate
    );
    PORT(
        clk_40mhz    : in STD_LOGIC;
        reset_n      : in STD_LOGIC;
        uart_txd     : out STD_LOGIC; -- uart tx line
        
        data         : in STD_LOGIC_VECTOR(7 downto 0); -- data to be transferred over UART TX
        start_tx     : in STD_LOGIC;                
        tx_active    : out STD_LOGIC; -- 1 active, 0 not active
        tx_done      : out STD_LOGIC  -- 1 tx done, 0 not
    );
end uart_tx;

architecture Behavioral of uart_tx is

    signal s_tx_data : std_logic_vector(7 downto 0) := X"00";

begin

    UART_TX_Process : process(clk_40mhz, reset_n)
        type states is (idle_state, start_bit_state, data_bits_state, stop_bit_state, last_state);
        variable state : states := idle_state;
        variable clock_counter : integer range 0 to CLOCK_NUMBER-1 := 0;
        variable bit_counter : integer range 0 to 7 := 0;
    begin
        
        if reset_n = '0' then
            state := idle_state;
            
        elsif rising_edge(clk_40mhz) then
        
            case state is
                when idle_state =>
                    uart_txd <= '1'; -- UART Idle is high
                    tx_done <= '0';
                    tx_active <= '0';
                    clock_counter := 0;
                    bit_counter := 0;
                    
                    if start_tx = '1' then
                        s_tx_data <= data;
                        state := start_bit_state;
                    else
                        state := idle_state;
                    end if;
                    
                when start_bit_state =>
                    tx_active <= '1';
                    uart_txd <= '0'; -- send start bit
                    
                    if clock_counter < CLOCK_NUMBER - 1 then
                        clock_counter := clock_counter + 1;
                        state := start_bit_state;
                    else
                        clock_counter := 0;
                        state := data_bits_state;
                    end if;
                
                when data_bits_state =>
                    
                    uart_txd <= s_tx_data(bit_counter); -- send each bit
                    
                    if clock_counter < CLOCK_NUMBER - 1 then
                        clock_counter := clock_counter + 1;
                        state := data_bits_state;
                    else
                        clock_counter := 0;
                        
                        -- Checking if all bits are send over uart.
                        if bit_counter < 7 then
                            bit_counter := bit_counter + 1;
                            state := data_bits_state;
                         else
                            bit_counter := 0;
                            state := stop_bit_state;
                         end if;
                    end if;
                
                when stop_bit_state =>
                
                    uart_txd <= '1'; -- send stop bit
                    
                    if clock_counter < CLOCK_NUMBER - 1 then
                        clock_counter := clock_counter + 1;
                        state := stop_bit_state;
                    else
                        clock_counter := 0;                       
                        tx_done <= '1';
                        state := last_state;
                        
                    end if;    
                
                when last_state =>
                
                    tx_active <= '0';
                    tx_done <= '1';
                    state := idle_state;
                
                when others =>
                    state := idle_state;
            
            end case;
        end if;    
    end process;

end Behavioral;











