@asar 1.71
incsrc "../Global/Global_Definitions.asm"
incsrc "../Global/Global_Macros.asm"

if !FileType == !FileType_InitializeROM
	!PathToFile = ""
	%InitializeROM(!GameID, !GameID, !ROMID)
elseif !FileType == 255
!TEMP = $008000
!Loop = 0
while !TEMP < $1E8000 || canread1(!TEMP)
org !TEMP
db $53,$54,$41,$52
dw Label!{Loop}_End-Label!{Loop}-$01
dw (Label!{Loop}_End-Label!{Loop}-$01)^$FFFF
Label!{Loop}:
skip $7FF8
.End:
!TEMP #= !TEMP+$010000
!Loop #= !Loop+1
endif
elseif !FileType == !FileType_SNESROM
	!PathToFile = ""
	%StartOfROM(!GameID, !GameID, !ROMID)
	%EndofROM(!GameID, !GameID, !ROMID)
elseif !FileType == !FileType_FinalizeROM
	!PathToFile = ""
	%FinalizeROM(!GameID, !GameID, !ROMID)
elseif !FileType == !FileType_DisplayChecksum
	!PathToFile = ""
	%DisplayFinalChecksum(!GameID, !GameID, !ROMID)
elseif !FileType == !FileType_SPC700File
	%InitializeSPCROM(!GameID, !GameID, !ROMID)
elseif !FileType == !FileType_SuperFXFile
	%InitializeSuperFXROM(!GameID, !GameID, !ROMID)
elseif !FileType == !FileType_FirmwareCopy
	!PathToFile = ""
	%GetFirmwareFile(!GameID, !GameID, !ROMID)
elseif !FileType == !FileType_MSU1DataFile
	%InitializeMSU1ROM(!GameID, !GameID, !ROMID)
elseif !FileType == !FileType_SaveFile
	%GenerateSaveFile(!GameID, !GameID, !ROMID)
else
	error "Invalid \!FileType parameter"
endif
