############## NET - IOSTANDARD ######################
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
#############SPI Configurate Setting##################
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
############## clock define###########################
set_property PACKAGE_PIN R4 [get_ports sys_clk_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports sys_clk_p]
#################reset setting########################
set_property IOSTANDARD LVCMOS15 [get_ports rstn]
set_property PACKAGE_PIN T6 [get_ports rstn]
#############SPI Setting##############################
set_property PACKAGE_PIN B22 [get_ports csb]
set_property IOSTANDARD LVCMOS33 [get_ports csb]

set_property PACKAGE_PIN C22 [get_ports miso]
set_property IOSTANDARD LVCMOS33 [get_ports miso]
set_property SLEW FAST [get_ports miso]

set_property PACKAGE_PIN A20 [get_ports mosi]
set_property IOSTANDARD LVCMOS33 [get_ports mosi]

set_property PACKAGE_PIN B20 [get_ports sck]
set_property IOSTANDARD LVCMOS33 [get_ports sck]
###################MDIO##############################
set_property PACKAGE_PIN J17 [get_ports MDC_0]
set_property IOSTANDARD LVCMOS33 [get_ports MDC_0]
set_property PACKAGE_PIN AB21 [get_ports MDC_1]
set_property IOSTANDARD LVCMOS33 [get_ports MDC_1]
set_property PACKAGE_PIN V20 [get_ports MDC_2]
set_property IOSTANDARD LVCMOS33 [get_ports MDC_2]
set_property PACKAGE_PIN V18 [get_ports MDC_3]
set_property IOSTANDARD LVCMOS33 [get_ports MDC_3]
set_property PACKAGE_PIN L16 [get_ports MDIO_0]
set_property IOSTANDARD LVCMOS33 [get_ports MDIO_0]
set_property PACKAGE_PIN AB22 [get_ports MDIO_1]
set_property IOSTANDARD LVCMOS33 [get_ports MDIO_1]
set_property PACKAGE_PIN V19 [get_ports MDIO_2]
set_property IOSTANDARD LVCMOS33 [get_ports MDIO_2]
set_property PACKAGE_PIN U20 [get_ports MDIO_3]
set_property IOSTANDARD LVCMOS33 [get_ports MDIO_3]
set_property PULLUP true [get_ports MDC_0]
set_property SLEW SLOW [get_ports MDC_0]
set_property PULLUP true [get_ports MDIO_0]
set_property PULLUP true [get_ports MDC_1]
set_property SLEW SLOW [get_ports MDIO_1]
set_property PULLUP true [get_ports MDIO_1]
set_property PULLUP true [get_ports MDC_2]
set_property SLEW SLOW [get_ports MDIO_2]
set_property PULLUP true [get_ports MDIO_2]
set_property PULLUP true [get_ports MDC_3]
set_property SLEW SLOW [get_ports MDIO_3]
set_property PULLUP true [get_ports MDIO_3]
#############LED Setting###########################
set_property PACKAGE_PIN E17 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN F16 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
############## ethernet PORT0 RX define############
set_property IOSTANDARD LVCMOS33 [get_ports GMII_RX_CLK_0]
set_property PACKAGE_PIN K18 [get_ports GMII_RX_CLK_0]

set_property IOSTANDARD LVCMOS33 [get_ports GMII_RX_DV_0]
set_property PACKAGE_PIN M22 [get_ports GMII_RX_DV_0]

set_property IOSTANDARD LVCMOS33 [get_ports GMII_RX_ER_0]
set_property PACKAGE_PIN N18 [get_ports GMII_RX_ER_0]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_0[0]}]
set_property PACKAGE_PIN N22 [get_ports {GMII_RXD_0[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_0[1]}]
set_property PACKAGE_PIN H18 [get_ports {GMII_RXD_0[1]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_0[2]}]
set_property PACKAGE_PIN H17 [get_ports {GMII_RXD_0[2]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_0[3]}]
set_property PACKAGE_PIN M21 [get_ports {GMII_RXD_0[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_0[4]}]
set_property PACKAGE_PIN L21 [get_ports {GMII_RXD_0[4]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_0[5]}]
set_property PACKAGE_PIN N20 [get_ports {GMII_RXD_0[5]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_0[6]}]
set_property PACKAGE_PIN M20 [get_ports {GMII_RXD_0[6]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_0[7]}]
set_property PACKAGE_PIN N19 [get_ports {GMII_RXD_0[7]}]
############## ethernet PORT0 TX define##############
set_property IOSTANDARD LVCMOS33 [get_ports MII_TX_CLK_0]
set_property PACKAGE_PIN K21 [get_ports MII_TX_CLK_0]

set_property IOSTANDARD LVCMOS33 [get_ports GMII_TX_CLK_0]
set_property PACKAGE_PIN G21 [get_ports GMII_TX_CLK_0]

set_property IOSTANDARD LVCMOS33 [get_ports GMII_TX_EN_0]
set_property PACKAGE_PIN G22 [get_ports GMII_TX_EN_0]

set_property IOSTANDARD LVCMOS33 [get_ports GMII_TX_ER_0]
set_property PACKAGE_PIN K17 [get_ports GMII_TX_ER_0]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_0[0]}]
set_property PACKAGE_PIN D22 [get_ports {GMII_TXD_0[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_0[1]}]
set_property PACKAGE_PIN H20 [get_ports {GMII_TXD_0[1]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_0[2]}]
set_property PACKAGE_PIN H22 [get_ports {GMII_TXD_0[2]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_0[3]}]
set_property PACKAGE_PIN J22 [get_ports {GMII_TXD_0[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_0[4]}]
set_property PACKAGE_PIN K22 [get_ports {GMII_TXD_0[4]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_0[5]}]
set_property PACKAGE_PIN L19 [get_ports {GMII_TXD_0[5]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_0[6]}]
set_property PACKAGE_PIN K19 [get_ports {GMII_TXD_0[6]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_0[7]}]
set_property PACKAGE_PIN L20 [get_ports {GMII_TXD_0[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports phy_rstn_0]
set_property PACKAGE_PIN G20 [get_ports phy_rstn_0]

set_property SLEW FAST [get_ports {GMII_TX_EN_0 GMII_TX_ER_0 GMII_TXD_0[*]}]
############## ethernet PORT1 RX define############
set_property IOSTANDARD LVCMOS33 [get_ports GMII_RX_CLK_1]
set_property PACKAGE_PIN J20 [get_ports GMII_RX_CLK_1]

set_property IOSTANDARD LVCMOS33 [get_ports GMII_RX_DV_1]
set_property PACKAGE_PIN L13 [get_ports GMII_RX_DV_1]

set_property IOSTANDARD LVCMOS33 [get_ports GMII_RX_ER_1]
set_property PACKAGE_PIN G13 [get_ports GMII_RX_ER_1]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_1[0]}]
set_property PACKAGE_PIN M13 [get_ports {GMII_RXD_1[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_1[1]}]
set_property PACKAGE_PIN K14 [get_ports {GMII_RXD_1[1]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_1[2]}]
set_property PACKAGE_PIN K13 [get_ports {GMII_RXD_1[2]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_1[3]}]
set_property PACKAGE_PIN J14 [get_ports {GMII_RXD_1[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_1[4]}]
set_property PACKAGE_PIN H14 [get_ports {GMII_RXD_1[4]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_1[5]}]
set_property PACKAGE_PIN H15 [get_ports {GMII_RXD_1[5]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_1[6]}]
set_property PACKAGE_PIN J15 [get_ports {GMII_RXD_1[6]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_1[7]}]
set_property PACKAGE_PIN H13 [get_ports {GMII_RXD_1[7]}]
############## ethernet PORT1 TX define##############
set_property IOSTANDARD LVCMOS33 [get_ports MII_TX_CLK_1]
set_property PACKAGE_PIN T14 [get_ports MII_TX_CLK_1]

set_property IOSTANDARD LVCMOS33 [get_ports GMII_TX_CLK_1]
set_property PACKAGE_PIN M16 [get_ports GMII_TX_CLK_1]

set_property IOSTANDARD LVCMOS33 [get_ports GMII_TX_EN_1]
set_property PACKAGE_PIN M15 [get_ports GMII_TX_EN_1]

set_property IOSTANDARD LVCMOS33 [get_ports GMII_TX_ER_1]
set_property PACKAGE_PIN T15 [get_ports GMII_TX_ER_1]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_1[0]}]
set_property PACKAGE_PIN L15 [get_ports {GMII_TXD_1[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_1[1]}]
set_property PACKAGE_PIN K16 [get_ports {GMII_TXD_1[1]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_1[2]}]
set_property PACKAGE_PIN W15 [get_ports {GMII_TXD_1[2]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_1[3]}]
set_property PACKAGE_PIN W16 [get_ports {GMII_TXD_1[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_1[4]}]
set_property PACKAGE_PIN V17 [get_ports {GMII_TXD_1[4]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_1[5]}]
set_property PACKAGE_PIN W17 [get_ports {GMII_TXD_1[5]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_1[6]}]
set_property PACKAGE_PIN U15 [get_ports {GMII_TXD_1[6]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_1[7]}]
set_property PACKAGE_PIN V15 [get_ports {GMII_TXD_1[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports phy_rstn_1]
set_property PACKAGE_PIN L14 [get_ports phy_rstn_1]

set_property SLEW FAST [get_ports {GMII_TX_EN_1 GMII_TX_ER_1 GMII_TXD_1[*]}]
############## ethernet PORT2 RX define############
set_property IOSTANDARD LVCMOS33 [get_ports GMII_RX_CLK_2]
set_property PACKAGE_PIN V13 [get_ports GMII_RX_CLK_2]

set_property IOSTANDARD LVCMOS33 [get_ports GMII_RX_DV_2]
set_property PACKAGE_PIN AA20 [get_ports GMII_RX_DV_2]

set_property IOSTANDARD LVCMOS33 [get_ports GMII_RX_ER_2]
set_property PACKAGE_PIN U21 [get_ports GMII_RX_ER_2]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_2[0]}]
set_property PACKAGE_PIN AB20 [get_ports {GMII_RXD_2[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_2[1]}]
set_property PACKAGE_PIN AA19 [get_ports {GMII_RXD_2[1]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_2[2]}]
set_property PACKAGE_PIN AA18 [get_ports {GMII_RXD_2[2]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_2[3]}]
set_property PACKAGE_PIN AB18 [get_ports {GMII_RXD_2[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_2[4]}]
set_property PACKAGE_PIN Y17 [get_ports {GMII_RXD_2[4]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_2[5]}]
set_property PACKAGE_PIN W22 [get_ports {GMII_RXD_2[5]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_2[6]}]
set_property PACKAGE_PIN W21 [get_ports {GMII_RXD_2[6]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_2[7]}]
set_property PACKAGE_PIN T21 [get_ports {GMII_RXD_2[7]}]
############## ethernet PORT2 TX define##############
set_property IOSTANDARD LVCMOS33 [get_ports MII_TX_CLK_2]
set_property PACKAGE_PIN V10 [get_ports MII_TX_CLK_2]

set_property IOSTANDARD LVCMOS33 [get_ports GMII_TX_CLK_2]
set_property PACKAGE_PIN AA21 [get_ports GMII_TX_CLK_2]

set_property IOSTANDARD LVCMOS33 [get_ports GMII_TX_EN_2]
set_property PACKAGE_PIN V14 [get_ports GMII_TX_EN_2]

set_property IOSTANDARD LVCMOS33 [get_ports GMII_TX_ER_2]
set_property PACKAGE_PIN AA9 [get_ports GMII_TX_ER_2]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_2[0]}]
set_property PACKAGE_PIN W11 [get_ports {GMII_TXD_2[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_2[1]}]
set_property PACKAGE_PIN W12 [get_ports {GMII_TXD_2[1]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_2[2]}]
set_property PACKAGE_PIN Y11 [get_ports {GMII_TXD_2[2]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_2[3]}]
set_property PACKAGE_PIN Y12 [get_ports {GMII_TXD_2[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_2[4]}]
set_property PACKAGE_PIN W10 [get_ports {GMII_TXD_2[4]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_2[5]}]
set_property PACKAGE_PIN AA11 [get_ports {GMII_TXD_2[5]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_2[6]}]
set_property PACKAGE_PIN AA10 [get_ports {GMII_TXD_2[6]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_2[7]}]
set_property PACKAGE_PIN AB10 [get_ports {GMII_TXD_2[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports phy_rstn_2]
set_property PACKAGE_PIN T20 [get_ports phy_rstn_2]

set_property SLEW FAST [get_ports {GMII_TX_EN_2 GMII_TX_ER_2 GMII_TXD_2[*]}]
############## ethernet PORT3 RX define############
set_property IOSTANDARD LVCMOS33 [get_ports GMII_RX_CLK_3]
set_property PACKAGE_PIN Y18 [get_ports GMII_RX_CLK_3]

set_property IOSTANDARD LVCMOS33 [get_ports GMII_RX_DV_3]
set_property PACKAGE_PIN W20 [get_ports GMII_RX_DV_3]

set_property IOSTANDARD LVCMOS33 [get_ports GMII_RX_ER_3]
set_property PACKAGE_PIN N13 [get_ports GMII_RX_ER_3]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_3[0]}]
set_property PACKAGE_PIN W19 [get_ports {GMII_RXD_3[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_3[1]}]
set_property PACKAGE_PIN Y19 [get_ports {GMII_RXD_3[1]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_3[2]}]
set_property PACKAGE_PIN V22 [get_ports {GMII_RXD_3[2]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_3[3]}]
set_property PACKAGE_PIN U22 [get_ports {GMII_RXD_3[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_3[4]}]
set_property PACKAGE_PIN T18 [get_ports {GMII_RXD_3[4]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_3[5]}]
set_property PACKAGE_PIN R18 [get_ports {GMII_RXD_3[5]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_3[6]}]
set_property PACKAGE_PIN R14 [get_ports {GMII_RXD_3[6]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_RXD_3[7]}]
set_property PACKAGE_PIN P14 [get_ports {GMII_RXD_3[7]}]
############## ethernet PORT3 TX define##############
set_property IOSTANDARD LVCMOS33 [get_ports MII_TX_CLK_3]
set_property PACKAGE_PIN U16 [get_ports MII_TX_CLK_3]

set_property IOSTANDARD LVCMOS33 [get_ports GMII_TX_CLK_3]
set_property PACKAGE_PIN P20 [get_ports GMII_TX_CLK_3]

set_property IOSTANDARD LVCMOS33 [get_ports GMII_TX_EN_3]
set_property PACKAGE_PIN P16 [get_ports GMII_TX_EN_3]

set_property IOSTANDARD LVCMOS33 [get_ports GMII_TX_ER_3]
set_property PACKAGE_PIN R19 [get_ports GMII_TX_ER_3]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_3[0]}]
set_property PACKAGE_PIN R17 [get_ports {GMII_TXD_3[0]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_3[1]}]
set_property PACKAGE_PIN P15 [get_ports {GMII_TXD_3[1]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_3[2]}]
set_property PACKAGE_PIN N17 [get_ports {GMII_TXD_3[2]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_3[3]}]
set_property PACKAGE_PIN P17 [get_ports {GMII_TXD_3[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_3[4]}]
set_property PACKAGE_PIN T16 [get_ports {GMII_TXD_3[4]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_3[5]}]
set_property PACKAGE_PIN U17 [get_ports {GMII_TXD_3[5]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_3[6]}]
set_property PACKAGE_PIN U18 [get_ports {GMII_TXD_3[6]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GMII_TXD_3[7]}]
set_property PACKAGE_PIN P19 [get_ports {GMII_TXD_3[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports phy_rstn_3]
set_property PACKAGE_PIN R16 [get_ports phy_rstn_3]

set_property SLEW FAST [get_ports {GMII_TX_EN_3 GMII_TX_ER_3 GMII_TXD_3[*]}]