library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx_sim is
end uart_tx_sim;

architecture sim of uart_tx_sim is

    --------------------------------------------------------------------
    -- DUT declaration
    --------------------------------------------------------------------
    component uart_tx is
        generic(
            CLOCK_NUMBER : integer := 347  -- 40MHz / 115200 baud
        );
        port(
            clk_40mhz  : in  std_logic;
            reset_n    : in  std_logic;
            uart_txd   : out std_logic;
            data       : in  std_logic_vector(7 downto 0);
            start_tx   : in  std_logic;
            tx_active  : out std_logic;
            tx_done    : out std_logic
        );
    end component;

    --------------------------------------------------------------------
    -- Signals
    --------------------------------------------------------------------
    signal clk        : std_logic := '0';
    signal reset_n    : std_logic := '0';
    signal uart_txd   : std_logic;
    signal data_in    : std_logic_vector(7 downto 0) := (others => '0');
    signal start_tx   : std_logic := '0';
    signal tx_active  : std_logic;
    signal tx_done    : std_logic;

    constant CLK_PERIOD : time := 25 ns;  -- 40 MHz clock

begin

    --------------------------------------------------------------------
    -- Clock generation
    --------------------------------------------------------------------
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    --------------------------------------------------------------------
    -- DUT instantiation
    --------------------------------------------------------------------
    uut : uart_tx
        generic map (
            CLOCK_NUMBER => 347
        )
        port map (
            clk_40mhz  => clk,
            reset_n    => reset_n,
            uart_txd   => uart_txd,
            data       => data_in,
            start_tx   => start_tx,
            tx_active  => tx_active,
            tx_done    => tx_done
        );

    --------------------------------------------------------------------
    -- Stimulus process
    --------------------------------------------------------------------
    stim_proc : process
    begin
        -- Apply reset for 200 ns
        reset_n <= '0';
        wait for 200 ns;
        reset_n <= '1';
        wait for 100 ns;

        ----------------------------------------------------------------
        -- Send ASCII 'A' (0x41)
        ----------------------------------------------------------------
        data_in <= x"41";
        start_tx <= '1';
        wait for CLK_PERIOD;
        start_tx <= '0';

        wait until tx_done = '1';
        wait for 1 us;

        ----------------------------------------------------------------
        -- Send pattern 0x55
        ----------------------------------------------------------------
        data_in <= x"55";
        start_tx <= '1';
        wait for CLK_PERIOD;
        start_tx <= '0';

        wait until tx_done = '1';
        wait for 1 us;

        ----------------------------------------------------------------
        -- Send ASCII 'Z' (0x5A)
        ----------------------------------------------------------------
        data_in <= x"5A";
        start_tx <= '1';
        wait for CLK_PERIOD;
        start_tx <= '0';

        wait until tx_done = '1';
        wait for 1 us;

        -- End simulation
        wait;
    end process;

end sim;
