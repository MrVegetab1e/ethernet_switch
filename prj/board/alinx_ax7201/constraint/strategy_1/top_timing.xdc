##############crystal clock define###########################
create_clock -period 5.000 -name sys_clk_p [get_ports sys_clk_p]
set_input_jitter sys_clk_p 0.002
############## ethernet PORT0 RX GMII CLOCK define############
create_clock -period 8.000 -name GMII_RX_CLK_0 [get_ports GMII_RX_CLK_0]
############## ethernet PORT0 TX MII CLOCK define##############
create_clock -period 40.000 -name MII_TX_CLK_0 [get_ports MII_TX_CLK_0]
############## ethernet PORT1 RX GMII CLOCK define############
create_clock -period 8.000 -name GMII_RX_CLK_1 [get_ports GMII_RX_CLK_1]
############## ethernet PORT1 TX MII CLOCKdefine##############
create_clock -period 40.000 -name MII_TX_CLK_1 [get_ports MII_TX_CLK_1]
############## ethernet PORT2 RX GMII CLOCK define############
create_clock -period 8.000 -name GMII_RX_CLK_2 [get_ports GMII_RX_CLK_2]
############## ethernet PORT2 TX MII CLOCK define##############
create_clock -period 40.000 -name MII_TX_CLK_2 [get_ports MII_TX_CLK_2]
############## ethernet PORT3 RX GMII CLOCK define############
create_clock -period 8.000 -name GMII_RX_CLK_3 [get_ports GMII_RX_CLK_3]
############## ethernet PORT3 TX MII CLOCK define##############
create_clock -period 40.000 -name MII_TX_CLK_3 [get_ports MII_TX_CLK_3]
############## SPI sck define ###############
create_clock -period 60.000 -name sck [get_ports sck]
set_input_jitter sys_clk_p 0.5
############## generated clock constraint##############
create_generated_clock -name emac0_ifclk_gmii -divide_by 1 [get_pins u_mac_top_0/u_mac_t_gmii/BUFGMUX_inst/O] -source [get_pins u_mac_top_0/u_mac_t_gmii/clk_out2] -add -master_clock clk_out2_clk_wiz_0
create_generated_clock -name emac0_ifclk_mii  -divide_by 1 [get_pins u_mac_top_0/u_mac_t_gmii/BUFGMUX_inst/O] -source [get_pins u_mac_top_0/u_mac_t_gmii/MII_TX_CLK_0_IBUF] -add -master_clock MII_TX_CLK_0

create_generated_clock -name emac1_ifclk_gmii -divide_by 1 [get_pins u_mac_top_1/u_mac_t_gmii/BUFGMUX_inst/O] -source [get_pins u_mac_top_1/u_mac_t_gmii/clk_out2] -add -master_clock clk_out2_clk_wiz_0
create_generated_clock -name emac1_ifclk_mii  -divide_by 1 [get_pins u_mac_top_1/u_mac_t_gmii/BUFGMUX_inst/O] -source [get_pins u_mac_top_1/u_mac_t_gmii/MII_TX_CLK_1_IBUF] -add -master_clock MII_TX_CLK_1

create_generated_clock -name emac2_ifclk_gmii -divide_by 1 [get_pins u_mac_top_2/u_mac_t_gmii/BUFGMUX_inst/O] -source [get_pins u_mac_top_2/u_mac_t_gmii/clk_out2] -add -master_clock clk_out2_clk_wiz_0
create_generated_clock -name emac2_ifclk_mii  -divide_by 1 [get_pins u_mac_top_2/u_mac_t_gmii/BUFGMUX_inst/O] -source [get_pins u_mac_top_2/u_mac_t_gmii/MII_TX_CLK_2_IBUF] -add -master_clock MII_TX_CLK_2

create_generated_clock -name emac3_ifclk_gmii -divide_by 1 [get_pins u_mac_top_3/u_mac_t_gmii/BUFGMUX_inst/O] -source [get_pins u_mac_top_3/u_mac_t_gmii/clk_out2] -add -master_clock clk_out2_clk_wiz_0
create_generated_clock -name emac3_ifclk_mii  -divide_by 1 [get_pins u_mac_top_3/u_mac_t_gmii/BUFGMUX_inst/O] -source [get_pins u_mac_top_3/u_mac_t_gmii/MII_TX_CLK_3_IBUF] -add -master_clock MII_TX_CLK_3

create_generated_clock -name MDC_0 -source [get_pins u_pll/clk_out2] -divide_by 250 [get_ports MDC_0]
create_generated_clock -name MDC_1 -source [get_pins u_pll/clk_out2] -divide_by 250 [get_ports MDC_1]
create_generated_clock -name MDC_2 -source [get_pins u_pll/clk_out2] -divide_by 250 [get_ports MDC_2]
create_generated_clock -name MDC_3 -source [get_pins u_pll/clk_out2] -divide_by 250 [get_ports MDC_3]
############## create clock constraint##############
set_input_delay -clock [get_clocks sck] -clock_fall -min -1.0 [get_ports {mosi csb}]
set_input_delay -clock [get_clocks sck] -clock_fall -max  5.0 [get_ports {mosi csb}]
set_output_delay -clock [get_clocks sck] -min -3.0 [get_ports {miso}]
set_output_delay -clock [get_clocks sck] -max  7.0 [get_ports {miso}]
set_clock_uncertainty -from sck -to clk_out1_clk_wiz_0 -setup 2.500
set_clock_uncertainty -from clk_out1_clk_wiz_0 -to sck -setup 2.500
set_multicycle_path -setup 3 -end -from [get_clocks sck] -to [get_clocks clk_out1_clk_wiz_0]
# set_multicycle_path -hold 2 -end -from [get_clocks sck] -to [get_clocks clk_out1_clk_wiz_0]
set_false_path -hold -from [get_clocks sck] -to [get_clocks clk_out1_clk_wiz_0]
set_multicycle_path -setup 5 -start -from [get_clocks clk_out1_clk_wiz_0] -to [get_clocks sck]
# set_multicycle_path -hold 2 -start -from [get_clocks clk_out1_clk_wiz_0] -to [get_clocks sck]
set_false_path -hold -from [get_clocks clk_out1_clk_wiz_0] -to [get_clocks sck]

set_input_delay -clock [get_clocks GMII_RX_CLK_0] -min 0.0 [get_ports {GMII_RX_DV_0 GMII_RX_ER_0 GMII_RXD_0[*]}]
set_input_delay -clock [get_clocks GMII_RX_CLK_0] -max 6.0 [get_ports {GMII_RX_DV_0 GMII_RX_ER_0 GMII_RXD_0[*]}]

set_input_delay -clock [get_clocks GMII_RX_CLK_1] -min 0.0 [get_ports {GMII_RX_DV_1 GMII_RX_ER_1 GMII_RXD_1[*]}]
set_input_delay -clock [get_clocks GMII_RX_CLK_1] -max 6.0 [get_ports {GMII_RX_DV_1 GMII_RX_ER_1 GMII_RXD_1[*]}]

set_input_delay -clock [get_clocks GMII_RX_CLK_2] -min 0.0 [get_ports {GMII_RX_DV_2 GMII_RX_ER_2 GMII_RXD_2[*]}]
set_input_delay -clock [get_clocks GMII_RX_CLK_2] -max 6.0 [get_ports {GMII_RX_DV_2 GMII_RX_ER_2 GMII_RXD_2[*]}]

set_input_delay -clock [get_clocks GMII_RX_CLK_3] -min 0.0 [get_ports {GMII_RX_DV_3 GMII_RX_ER_3 GMII_RXD_3[*]}]
set_input_delay -clock [get_clocks GMII_RX_CLK_3] -max 6.0 [get_ports {GMII_RX_DV_3 GMII_RX_ER_3 GMII_RXD_3[*]}]

set_output_delay -clock [get_clocks emac0_ifclk_gmii] -min -1.0 [get_ports {GMII_TX_EN_0 GMII_TX_ER_0 GMII_TXD_0[*]}]
set_output_delay -clock [get_clocks emac0_ifclk_gmii] -max  5.0 [get_ports {GMII_TX_EN_0 GMII_TX_ER_0 GMII_TXD_0[*]}]
set_output_delay -clock [get_clocks emac0_ifclk_mii]  -min -1.0 [get_ports {GMII_TX_EN_0 GMII_TX_ER_0 GMII_TXD_0[*]}]
set_output_delay -clock [get_clocks emac0_ifclk_mii]  -max  5.0 [get_ports {GMII_TX_EN_0 GMII_TX_ER_0 GMII_TXD_0[*]}]

set_output_delay -clock [get_clocks emac1_ifclk_gmii] -min -1.0 [get_ports {GMII_TX_EN_1 GMII_TX_ER_1 GMII_TXD_1[*]}]
set_output_delay -clock [get_clocks emac1_ifclk_gmii] -max  5.0 [get_ports {GMII_TX_EN_1 GMII_TX_ER_1 GMII_TXD_1[*]}]
set_output_delay -clock [get_clocks emac1_ifclk_mii]  -min -1.0 [get_ports {GMII_TX_EN_1 GMII_TX_ER_1 GMII_TXD_1[*]}]
set_output_delay -clock [get_clocks emac1_ifclk_mii]  -max  5.0 [get_ports {GMII_TX_EN_1 GMII_TX_ER_1 GMII_TXD_1[*]}]

set_output_delay -clock [get_clocks emac2_ifclk_gmii] -min -1.0 [get_ports {GMII_TX_EN_2 GMII_TX_ER_2 GMII_TXD_2[*]}]
set_output_delay -clock [get_clocks emac2_ifclk_gmii] -max  5.0 [get_ports {GMII_TX_EN_2 GMII_TX_ER_2 GMII_TXD_2[*]}]
set_output_delay -clock [get_clocks emac2_ifclk_mii]  -min -1.0 [get_ports {GMII_TX_EN_2 GMII_TX_ER_2 GMII_TXD_2[*]}]
set_output_delay -clock [get_clocks emac2_ifclk_mii]  -max  5.0 [get_ports {GMII_TX_EN_2 GMII_TX_ER_2 GMII_TXD_2[*]}]

set_output_delay -clock [get_clocks emac3_ifclk_gmii] -min -1.0 [get_ports {GMII_TX_EN_3 GMII_TX_ER_3 GMII_TXD_3[*]}]
set_output_delay -clock [get_clocks emac3_ifclk_gmii] -max  5.0 [get_ports {GMII_TX_EN_3 GMII_TX_ER_3 GMII_TXD_3[*]}]
set_output_delay -clock [get_clocks emac3_ifclk_mii]  -min -1.0 [get_ports {GMII_TX_EN_3 GMII_TX_ER_3 GMII_TXD_3[*]}]
set_output_delay -clock [get_clocks emac3_ifclk_mii]  -max  5.0 [get_ports {GMII_TX_EN_3 GMII_TX_ER_3 GMII_TXD_3[*]}]

set_clock_groups -logically_exclusive -group emac0_ifclk_mii -group emac0_ifclk_gmii
set_clock_groups -logically_exclusive -group emac1_ifclk_mii -group emac1_ifclk_gmii
set_clock_groups -logically_exclusive -group emac2_ifclk_mii -group emac2_ifclk_gmii
set_clock_groups -logically_exclusive -group emac3_ifclk_mii -group emac3_ifclk_gmii

set_clock_groups -asynchronous -group clk_out1_clk_wiz_0 -group GMII_RX_CLK_0
set_clock_groups -asynchronous -group clk_out1_clk_wiz_0 -group GMII_RX_CLK_1
set_clock_groups -asynchronous -group clk_out1_clk_wiz_0 -group GMII_RX_CLK_2
set_clock_groups -asynchronous -group clk_out1_clk_wiz_0 -group GMII_RX_CLK_3

set_clock_groups -asynchronous -group clk_out2_clk_wiz_0 -group GMII_RX_CLK_0
set_clock_groups -asynchronous -group clk_out2_clk_wiz_0 -group GMII_RX_CLK_1
set_clock_groups -asynchronous -group clk_out2_clk_wiz_0 -group GMII_RX_CLK_2
set_clock_groups -asynchronous -group clk_out2_clk_wiz_0 -group GMII_RX_CLK_3

set_clock_groups -asynchronous -group clk_out1_clk_wiz_0 -group MII_TX_CLK_0
set_clock_groups -asynchronous -group clk_out1_clk_wiz_0 -group MII_TX_CLK_1
set_clock_groups -asynchronous -group clk_out1_clk_wiz_0 -group MII_TX_CLK_2
set_clock_groups -asynchronous -group clk_out1_clk_wiz_0 -group MII_TX_CLK_3

set_clock_groups -asynchronous -group GMII_RX_CLK_0 -group MII_TX_CLK_0
set_clock_groups -asynchronous -group GMII_RX_CLK_1 -group MII_TX_CLK_1
set_clock_groups -asynchronous -group GMII_RX_CLK_2 -group MII_TX_CLK_2
set_clock_groups -asynchronous -group GMII_RX_CLK_3 -group MII_TX_CLK_3

set_clock_groups -asynchronous -group clk_out2_clk_wiz_0 -group MII_TX_CLK_0
set_clock_groups -asynchronous -group clk_out2_clk_wiz_0 -group MII_TX_CLK_1
set_clock_groups -asynchronous -group clk_out2_clk_wiz_0 -group MII_TX_CLK_2
set_clock_groups -asynchronous -group clk_out2_clk_wiz_0 -group MII_TX_CLK_3

set_clock_groups -asynchronous -group clk_out1_clk_wiz_0 -group emac0_ifclk_mii
set_clock_groups -asynchronous -group clk_out1_clk_wiz_0 -group emac1_ifclk_mii
set_clock_groups -asynchronous -group clk_out1_clk_wiz_0 -group emac2_ifclk_mii
set_clock_groups -asynchronous -group clk_out1_clk_wiz_0 -group emac3_ifclk_mii

set_clock_groups -asynchronous -group clk_out2_clk_wiz_0 -group emac0_ifclk_mii
set_clock_groups -asynchronous -group clk_out2_clk_wiz_0 -group emac1_ifclk_mii
set_clock_groups -asynchronous -group clk_out2_clk_wiz_0 -group emac2_ifclk_mii
set_clock_groups -asynchronous -group clk_out2_clk_wiz_0 -group emac3_ifclk_mii

set_clock_groups -asynchronous -group GMII_RX_CLK_0 -group emac0_ifclk_mii
set_clock_groups -asynchronous -group GMII_RX_CLK_1 -group emac1_ifclk_mii
set_clock_groups -asynchronous -group GMII_RX_CLK_2 -group emac2_ifclk_mii
set_clock_groups -asynchronous -group GMII_RX_CLK_3 -group emac3_ifclk_mii

set_clock_groups -asynchronous -group GMII_RX_CLK_0 -group emac0_ifclk_gmii
set_clock_groups -asynchronous -group GMII_RX_CLK_1 -group emac1_ifclk_gmii
set_clock_groups -asynchronous -group GMII_RX_CLK_2 -group emac2_ifclk_gmii
set_clock_groups -asynchronous -group GMII_RX_CLK_3 -group emac3_ifclk_gmii

set_false_path -from [get_clocks sys_clk_p] -to [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks sys_clk_p] -to [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT1]]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets MII_TX_CLK_0_IBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets MII_TX_CLK_1_IBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets MII_TX_CLK_2_IBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets MII_TX_CLK_3_IBUF]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets u_pll/inst/clk_out2]