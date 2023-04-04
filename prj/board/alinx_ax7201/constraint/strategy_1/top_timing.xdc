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
############## generated clock constrain##############
create_generated_clock -name GMII_TX_CLK_0 -source [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT1] -multiply_by 1 [get_ports GMII_TX_CLK_0]

create_generated_clock -name GMII_TX_CLK_1 -source [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT1] -multiply_by 1 [get_ports GMII_TX_CLK_1]

create_generated_clock -name GMII_TX_CLK_2 -source [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT1] -multiply_by 1 [get_ports GMII_TX_CLK_2]

create_generated_clock -name GMII_TX_CLK_3 -source [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT1] -multiply_by 1 [get_ports GMII_TX_CLK_3]

create_generated_clock -name MDC_0 -source [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0] -divide_by 400 [get_ports MDC_0]

create_generated_clock -name MDC_1 -source [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0] -divide_by 400 [get_ports MDC_1]

create_generated_clock -name MDC_2 -source [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0] -divide_by 400 [get_ports MDC_2]

create_generated_clock -name MDC_3 -source [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0] -divide_by 400 [get_ports MDC_3]
############## create clock constrain##############
set_false_path -from [get_clocks sys_clk_p] -to [get_clocks GMII_RX_CLK_0]
set_false_path -from [get_clocks sys_clk_p] -to [get_clocks GMII_RX_CLK_1]
set_false_path -from [get_clocks sys_clk_p] -to [get_clocks GMII_RX_CLK_2]
set_false_path -from [get_clocks sys_clk_p] -to [get_clocks GMII_RX_CLK_3]
set_false_path -from [get_clocks sys_clk_p] -to [get_clocks MII_TX_CLK_0]
set_false_path -from [get_clocks sys_clk_p] -to [get_clocks MII_TX_CLK_1]
set_false_path -from [get_clocks sys_clk_p] -to [get_clocks MII_TX_CLK_2]
set_false_path -from [get_clocks sys_clk_p] -to [get_clocks MII_TX_CLK_3]

set_false_path -from [get_clocks GMII_RX_CLK_0] -to [get_clocks MII_TX_CLK_0]
set_false_path -from [get_clocks GMII_RX_CLK_1] -to [get_clocks MII_TX_CLK_1]
set_false_path -from [get_clocks GMII_RX_CLK_2] -to [get_clocks MII_TX_CLK_2]
set_false_path -from [get_clocks GMII_RX_CLK_3] -to [get_clocks MII_TX_CLK_3]

set_false_path -from [get_clocks GMII_RX_CLK_0] -to [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks GMII_RX_CLK_1] -to [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks GMII_RX_CLK_2] -to [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks GMII_RX_CLK_3] -to [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0]]

set_false_path -from [get_clocks MII_TX_CLK_0] -to [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks MII_TX_CLK_1] -to [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks MII_TX_CLK_2] -to [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks MII_TX_CLK_3] -to [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0]]

set_false_path -from [get_clocks MII_TX_CLK_0] -to [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT1]]
set_false_path -from [get_clocks MII_TX_CLK_1] -to [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT1]]
set_false_path -from [get_clocks MII_TX_CLK_2] -to [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT1]]
set_false_path -from [get_clocks MII_TX_CLK_3] -to [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT1]]

set_false_path -from [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks GMII_RX_CLK_0]
set_false_path -from [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks GMII_RX_CLK_1]
set_false_path -from [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks GMII_RX_CLK_2]
set_false_path -from [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks GMII_RX_CLK_3]

set_false_path -from [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks MII_TX_CLK_0]
set_false_path -from [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks MII_TX_CLK_1]
set_false_path -from [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks MII_TX_CLK_2]
set_false_path -from [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks MII_TX_CLK_3]

set_false_path -from [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT1]] -to [get_clocks MII_TX_CLK_0]
set_false_path -from [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT1]] -to [get_clocks MII_TX_CLK_1]
set_false_path -from [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT1]] -to [get_clocks MII_TX_CLK_2]
set_false_path -from [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT1]] -to [get_clocks MII_TX_CLK_3]

set_false_path -from [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT1]]
set_false_path -from [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT1]] -to [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0]]

set_false_path -from [get_clocks sys_clk_p] -to [get_clocks -of_objects [get_pins u_pll/inst/mmcm_adv_inst/CLKOUT0]]

set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets MII_TX_CLK_0_IBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets MII_TX_CLK_1_IBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets MII_TX_CLK_2_IBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets MII_TX_CLK_3_IBUF]