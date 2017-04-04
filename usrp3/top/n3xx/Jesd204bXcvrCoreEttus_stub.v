// Copyright 1986-2015 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2015.4.2 (win64) Build 1494164 Fri Feb 26 04:18:56 MST 2016
// Date        : Thu Apr 06 12:38:17 2017
// Host        : djepson-lt running 64-bit major release  (build 9200)
// Command     : write_verilog -mode synth_stub -force -file ./Jesd204bXcvrCoreEttus_stub.v
// Design      : Jesd204bXcvrCoreEttus
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z100ffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module Jesd204bXcvrCoreEttus(aReset, bReset, BusClk, ReliableClk40, FpgaClk1x, FpgaClk2x, bFpgaClksStable, bRegPortInAddress, bRegPortInData, bRegPortInRd, bRegPortInWt, bRegPortOutData, bRegPortOutReady, aLmkSync, fSysRefFpgaLvds_p, fSysRefFpgaLvds_n, fSysRef, JesdRefClk_p, JesdRefClk_n, bJesdRefClkPresent, aAdcRx_p, aAdcRx_n, aSyncAdcOut_p, aSyncAdcOut_n, aDacTx_p, aDacTx_n, aSyncDacIn_p, aSyncDacIn_n, fAdc0DataI, fAdc0DataQ, fAdc1DataI, fAdc1DataQ, fAdcDataValid, fDac0DataI, fDac0DataQ, fDac1DataI, fDac1DataQ, fDacReadyForInput, bDac0DataSettingsInvertA, bDac0DataSettingsInvertB, bDac0DataSettingsZeroA, bDac0DataSettingsZeroB, bDac0DataSettingsAisI, bDac0DataSettingsBisQ, bDac1DataSettingsInvertA, bDac1DataSettingsInvertB, bDac1DataSettingsZeroA, bDac1DataSettingsZeroB, bDac1DataSettingsAisI, bDac1DataSettingsBisQ, bAdc0DataSettingsInvertA, bAdc0DataSettingsInvertB, bAdc0DataSettingsZeroA, bAdc0DataSettingsZeroB, bAdc0DataSettingsAisI, bAdc0DataSettingsBisQ, bAdc1DataSettingsInvertA, bAdc1DataSettingsInvertB, bAdc1DataSettingsZeroA, bAdc1DataSettingsZeroB, bAdc1DataSettingsAisI, bAdc1DataSettingsBisQ, aDacSync, aAdcSync)
/* synthesis syn_black_box black_box_pad_pin="aReset,bReset,BusClk,ReliableClk40,FpgaClk1x,FpgaClk2x,bFpgaClksStable,bRegPortInAddress[15:0],bRegPortInData[31:0],bRegPortInRd,bRegPortInWt,bRegPortOutData[31:0],bRegPortOutReady,aLmkSync,fSysRefFpgaLvds_p,fSysRefFpgaLvds_n,fSysRef,JesdRefClk_p,JesdRefClk_n,bJesdRefClkPresent,aAdcRx_p[3:0],aAdcRx_n[3:0],aSyncAdcOut_p,aSyncAdcOut_n,aDacTx_p[3:0],aDacTx_n[3:0],aSyncDacIn_p,aSyncDacIn_n,fAdc0DataI[15:0],fAdc0DataQ[15:0],fAdc1DataI[15:0],fAdc1DataQ[15:0],fAdcDataValid,fDac0DataI[15:0],fDac0DataQ[15:0],fDac1DataI[15:0],fDac1DataQ[15:0],fDacReadyForInput,bDac0DataSettingsInvertA,bDac0DataSettingsInvertB,bDac0DataSettingsZeroA,bDac0DataSettingsZeroB,bDac0DataSettingsAisI,bDac0DataSettingsBisQ,bDac1DataSettingsInvertA,bDac1DataSettingsInvertB,bDac1DataSettingsZeroA,bDac1DataSettingsZeroB,bDac1DataSettingsAisI,bDac1DataSettingsBisQ,bAdc0DataSettingsInvertA,bAdc0DataSettingsInvertB,bAdc0DataSettingsZeroA,bAdc0DataSettingsZeroB,bAdc0DataSettingsAisI,bAdc0DataSettingsBisQ,bAdc1DataSettingsInvertA,bAdc1DataSettingsInvertB,bAdc1DataSettingsZeroA,bAdc1DataSettingsZeroB,bAdc1DataSettingsAisI,bAdc1DataSettingsBisQ,aDacSync,aAdcSync" */;
  input aReset;
  input bReset;
  input BusClk;
  input ReliableClk40;
  input FpgaClk1x;
  input FpgaClk2x;
  input bFpgaClksStable;
  input [15:0]bRegPortInAddress;
  input [31:0]bRegPortInData;
  input bRegPortInRd;
  input bRegPortInWt;
  output [31:0]bRegPortOutData;
  output bRegPortOutReady;
  output aLmkSync;
  input fSysRefFpgaLvds_p;
  input fSysRefFpgaLvds_n;
  output fSysRef;
  input JesdRefClk_p;
  input JesdRefClk_n;
  output bJesdRefClkPresent;
  input [3:0]aAdcRx_p;
  input [3:0]aAdcRx_n;
  output aSyncAdcOut_p;
  output aSyncAdcOut_n;
  output [3:0]aDacTx_p;
  output [3:0]aDacTx_n;
  input aSyncDacIn_p;
  input aSyncDacIn_n;
  output [15:0]fAdc0DataI;
  output [15:0]fAdc0DataQ;
  output [15:0]fAdc1DataI;
  output [15:0]fAdc1DataQ;
  output fAdcDataValid;
  input [15:0]fDac0DataI;
  input [15:0]fDac0DataQ;
  input [15:0]fDac1DataI;
  input [15:0]fDac1DataQ;
  output fDacReadyForInput;
  input bDac0DataSettingsInvertA;
  input bDac0DataSettingsInvertB;
  input bDac0DataSettingsZeroA;
  input bDac0DataSettingsZeroB;
  input bDac0DataSettingsAisI;
  input bDac0DataSettingsBisQ;
  input bDac1DataSettingsInvertA;
  input bDac1DataSettingsInvertB;
  input bDac1DataSettingsZeroA;
  input bDac1DataSettingsZeroB;
  input bDac1DataSettingsAisI;
  input bDac1DataSettingsBisQ;
  input bAdc0DataSettingsInvertA;
  input bAdc0DataSettingsInvertB;
  input bAdc0DataSettingsZeroA;
  input bAdc0DataSettingsZeroB;
  input bAdc0DataSettingsAisI;
  input bAdc0DataSettingsBisQ;
  input bAdc1DataSettingsInvertA;
  input bAdc1DataSettingsInvertB;
  input bAdc1DataSettingsZeroA;
  input bAdc1DataSettingsZeroB;
  input bAdc1DataSettingsAisI;
  input bAdc1DataSettingsBisQ;
  output aDacSync;
  output aAdcSync;
endmodule
