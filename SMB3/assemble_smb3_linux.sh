export PATH=../Global:${PATH}
export Input1=
export asarVer=asar
export GAMDID="SMB3"
export ROMVer=
export ROMExt=.sfc
export HackCheck=""
export HackName=""

echo Enter the ROM version you want to assemble.
echo Valid options: "SMB3_U", "SMB3_E", "SMB3_J"
echo For custom ROM versions, use "HACK_<HackName>, where <HackName> is the rest of the custom ROM Map file's name before the extension."

input(){
read Input1
${HackCheck=$Input1: -5}
if [[ "$Input1" == "" ]]; then exit_sh
elif [[ "$HackCheck" == "HACK_" ]]; then hack
elif [[ "$Input1" == "SMB3_U" ]]; then usa
elif [[ "$Input1" == "SMB3_E" ]]; then pal
elif [[ "$Input1" == "SMB3_J" ]]; then japan
fi

echo "$Input1" is not a valid ROM version.
export Input1=
input
}

hack(){
export ROMNAME=$Input1:~5,100%
export ROMVer=(Hack)
assemble
}

usa(){
export ROMVer=(U)
export ROMNAME="Super Mario Bros. 3"
assemble
}

pal(){
export ROMVer=(E)
export ROMNAME="Super Mario Bros. 3"
assemble
}

japan(){
export ROMVer=(J)
export ROMNAME="Super Mario Bros. 3"
assemble
}

assemble(){
export output="$ROMNAME $ROMVer$ROMExt"

if [ -e "$output" ]; then rm "$output"; fi
echo Assembling $ROMNAME $ROMVer$ROMExt ... this may take a minute.
echo

$asarVer --fix-checksum=on --define GameID="$GAMDID" --define ROMID="$Input1" --define FileType=0 ../Global/AssembleFile.asm "$output"

echo Assembling SMAS SPC700 engine...
$asarVer --define GameID="$GAMDID" --define ROMID="$Input1" --define FileType=4 --define PathToFile="../SMAS/SPC700/Engine.asm" ../Global/AssembleFile.asm ../SMAS/SPC700/Engine.bin

echo Assembling SMAS SPC700 main samples...
$asarVer --define GameID="$GAMDID" --define ROMID="$Input1" --define FileType=4 --define PathToFile="../SMAS/SPC700/MainSamples.asm" ../Global/AssembleFile.asm ../SMAS/SPC700/MainSamples.bin

echo Assembling SMB3 SPC700 level music bank...
$asarVer --define GameID="$GAMDID" --define ROMID="$Input1" --define FileType=4 --define PathToFile="../SMB3/SPC700/SMB3_Level_MusicBank.asm" ../Global/AssembleFile.asm ../SMB3/SPC700/SMB3_Level_MusicBank.bin

echo Assembling SMB3 SPC700 overworld music bank...
$asarVer --define GameID="$GAMDID" --define ROMID="$Input1" --define FileType=4 --define PathToFile="../SMB3/SPC700/SMB3_Overworld_MusicBank.asm" ../Global/AssembleFile.asm ../SMB3/SPC700/SMB3_Overworld_MusicBank.bin

echo Assembling ROM...
$asarVer --define GameID="$GAMDID" --define ROMID="$Input1" --define FileType=1 ../Global/AssembleFile.asm "$output"

if [ -e ../$GAMDID/Temp.txt ]; then rm ../$GAMDID/Temp.txt; fi
$asarVer --define GameID="$GAMDID" --define ROMID="$Input1" --define FileType=6 ../Global/AssembleFile.asm Temp.txt
Firmware=$(cat Temp.txt)
if [[ "$Firmware" == "NULL" ]]; then no_firmware
elif [ -e $Firmware ]; then no_firmware
elif [ -e ../Firmware/$Firmware ]; then copy_firmware
fi
no_firmware
}

copy_firmware(){
echo Copied $Firmware to the disassembly folder
copy ../Firmware/$Firmware $Firmware
}

no_firmware(){
if [ -e ../$GAMDID/Temp.txt ]; then rm ../$GAMDID/Temp.txt; fi

$asarVer --define GameID="$GAMDID" --define ROMID="$Input1" --define FileType=2 ../Global/AssembleFile.asm "$output"

$asarVer --fix-checksum=off --define GameID="$GAMDID" --define ROMID="$Input1" --define FileType=3 ../Global/AssembleFile.asm "$output"

echo Cleaning up...
if [ -e SMAS/SPC700/Engine.bin ]; then rm SMAS/SPC700/Engine.bin
elif [ -e SMAS/SPC700/MainSamples.bin ]; then rm SMAS/SPC700/MainSamples.bin
elif [ -e SPC700/SMB3_Level_MusicBank.bin ]; then rm SPC700/SMB3_Level_MusicBank.bin
elif [ -e SPC700/SMB3_Overworld_MusicBank.bin ]; then rm SPC700/SMB3_Overworld_MusicBank.bin
fi

echo
echo Done!
echo
echo Press Enter to re-assemble the chosen ROM.

input
}

exit_sh(){
exit
}

input
