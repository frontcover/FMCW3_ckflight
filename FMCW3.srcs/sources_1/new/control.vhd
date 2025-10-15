library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity control is
    generic (
        MAX_SAMPLES : integer := 8192 
    );
    Port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        muxout     : in  std_logic;

        -- ADC inputs
        adc_data_a : in  std_logic_vector(15 downto 0);
        adc_data_b : in  std_logic_vector(15 downto 0);
        adc_valid  : in  std_logic;

        -- ADC control outputs
        adc_oe      : out std_logic_vector(1 downto 0);
        adc_shdn    : out std_logic_vector(1 downto 0);
        pa_en       : out std_logic;
        config_done : in std_logic;

        -- USB interface
        usb_chipselect : out std_logic;
        usb_write_n    : out std_logic;
        usb_writedata  : out std_logic_vector(7 downto 0);
        usb_tx_full    : in  std_logic;
        
        microblaze_sampling_done : in std_logic
    );
end control;

architecture Behavioral of control is

    type state_type is (IDLE, RAMP, GAP_WAIT, USB_TX_IDLE, USB_TX_PULSE);
    signal state : state_type;

    -- Internal memory for ramp samples (16-bit A + 16-bit B)
    type mem_type is array (0 to MAX_SAMPLES-1) of std_logic_vector(31 downto 0);
    signal mem        : mem_type := (others => (others => '0'));
    signal sample_idx : integer range 0 to MAX_SAMPLES-1 := 0; -- Used during sampling to store data
    signal byte_sel   : integer range 0 to 3 := 0;    
    signal usb_idx    : integer range 0 to MAX_SAMPLES-1 := 0; -- used during usb transmission
    signal sample_count : integer range 0 to MAX_SAMPLES-1 := 0;
    signal adc_latched: std_logic_vector(31 downto 0);

begin

    -- Latch ADC data when valid
    process(clk)
    begin
        if rising_edge(clk) then
            if adc_valid = '1' then
                adc_latched <= adc_data_a & adc_data_b;
            end if;
        end if;
    end process;

    -- FSM sequential
    process(clk, reset)
    
    begin
    
        if reset = '1' then
            state           <= IDLE;
            sample_idx      <= 0;
            sample_count    <= 0;
            usb_idx         <= 0;
            byte_sel        <= 0;
            adc_oe          <= "11";
            adc_shdn        <= "11";
            pa_en           <= '0';
            usb_chipselect  <= '0';
            usb_write_n     <= '1';
            usb_writedata   <= (others => '0');

        elsif rising_edge(clk) then
            
            case state is
    
                when IDLE =>
                
                    adc_oe          <= "11";
                    adc_shdn        <= "11";
                    pa_en           <= '0';
                    usb_chipselect  <= '0';
                    usb_write_n     <= '1';
                    sample_idx      <= 0;
                    usb_idx         <= 0;
                    byte_sel        <= 0;
                    
                    -- When microblaze sends high to indicate that N seconds of sampling radar is done
                    -- the control logic stays in IDLE state.
                    -- Later config_done must be resetted since new radar recording can be started with new features.
                    if muxout = '1' and config_done = '1' and microblaze_sampling_done = '0' then
                        state <= RAMP;
                    else
                        state <= IDLE;
                    end if;

                when RAMP =>
                
                    adc_oe          <= "00";
                    adc_shdn        <= "00";                    
                    pa_en           <= '1';
                    usb_chipselect  <= '0';
                    usb_write_n     <= '1';

                    if adc_valid = '1' and sample_idx < MAX_SAMPLES then
                        mem(sample_idx) <= adc_latched;
                        sample_idx      <= sample_idx + 1;
                    end if;

                    if muxout = '0' and config_done = '1' then
                        sample_count    <= sample_idx;
                        state           <= GAP_WAIT;
                    end if;

                when GAP_WAIT =>
                
                    adc_oe          <= "11";
                    adc_shdn        <= "11";
                    pa_en           <= '0';
                    usb_chipselect  <= '0';
                    usb_write_n     <= '1';
                    usb_idx         <= 0;
                    byte_sel        <= 0;
                    state           <= USB_TX_IDLE;

                -- USB_TX_IDLE: setup next byte, write_n high
                -- this stage selects byte from current memory 32 bit data (8 bit tx per write)
                when USB_TX_IDLE =>
                    
                    -- usb tx needs one clock write_n 0 1 0 transition
                    usb_chipselect  <= '1';
                    usb_write_n     <= '1';
                    
                    if usb_idx < sample_count and usb_tx_full = '0' then
                    
                        -- drive data for next byte
                        -- adc stores 2 channel 16 bit data as concatenated 32 bit so select each byte
                        case byte_sel is
                            when 0      => usb_writedata <= mem(usb_idx)(31 downto 24);
                            when 1      => usb_writedata <= mem(usb_idx)(23 downto 16);
                            when 2      => usb_writedata <= mem(usb_idx)(15 downto 8);
                            when 3      => usb_writedata <= mem(usb_idx)(7 downto 0);
                            when others => usb_writedata <= (others => '0');
                        end case;
                    
                        state <= USB_TX_PULSE;
                    
                    elsif usb_idx >= sample_count then
                        -- usb transfer send all bytes before gap is finished so return to idle and wait ramp is correct way.
                        state <= IDLE;
                    end if;

                -- USB_TX_PULSE: pulse write_n low for 1 clock
                when USB_TX_PULSE =>
                   
                    usb_chipselect  <= '1';
                    usb_write_n     <= '0';                    

                    if byte_sel = 3 then
                        byte_sel    <= 0;
                        usb_idx     <= usb_idx + 1;
                    else
                        byte_sel <= byte_sel + 1;
                    end if;

                    state <= USB_TX_IDLE;

                when others =>
                    state <= IDLE;

            end case;
        end if;
    end process;

end Behavioral;
