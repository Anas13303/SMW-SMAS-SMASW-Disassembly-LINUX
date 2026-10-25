#!/bin/bash
memmap=lorom

echo "To fully extract all files for supported ROMs, you'll need one of the following ROMs in each group:"
echo - Graphics: All international versions and one Japanese version
echo - "International Random Chatter Sample: SMAS (USA)/SMAS (PAL)/SMAS+W (USA)/SMAS+W (PAL)"
echo - "Japanese Random Chatter Sample: SMAS (Japan)/SMAS (Japan Rev. 1)"
echo - Main Samples: Any
echo - Music: Any
echo - "SMW assets: SMAS+W (USA)/SMAS+W (PAL)"
echo - "Standalone Games Hack Assets: SMAS+W (USA)/SMAS+W (PAL)"
echo

yell(){
    fmt="$1";
    shift 1;
    printf "${fmt}\n" $@ >&2
}


die(){
    yell "$@"
    exit 1;
}

find_asar(){
    varname=${1:-ASAR}
    asar="$(which asar 2>/dev/null)"
    if [[ $? -eq 0 ]]; then
        echo "asar is ${asar}"
    else
        echo "default to asar path ../../Global/asar"
        asar=../../Global/asar
    fi;
    typeset -g "${varname}=${asar}"
    [[ -x ${asar} ]]
}

rom_versions=('SMAS (USA)' 'SMAS (PAL)' 'SMAS (Japan)' 'SMAS (Japan Rev. 1)' 'SMAS+W (USA)' 'SMAS+W (PAL)')

get_rom_version(){
    PS3="'$(basename ${2})' is? "
    echo "Place a headerless SMAS ROM named SMAS.sfc in this folder, then type the number representing what version SMAS.sfc is."
    select SELECTION in "${rom_versions[@]}"; do
        if [[ -z "${SELECTION}" ]]; then
            yell "bad selection"
            return 1;
        else
            typeset -g "${1}=${SELECTION}"
            break;
        fi;
    done;
}

coerce_rom_version_id(){
    typeset -n "ref=${1}";
    if [[ -z "${ref}" ]]; then
        yell "empty var ${1}"
        return 1;
    fi;

    for ((i=0; i<${#rom_versions[@]};i++)); do
        if [[ "${ref}" == "${rom_versions[$i]}" ]]; then
            echo "selected rom version '${ref}'"
            ref=${i};
            return
        fi;
    done;
    yell "unknown rom kind %s" "${2}"
    return 1;
}
set_rombit(){
    rb=
    case $1 in
    0) rb='$0001';;
    1) rb='$0002';;
    2) rb='$0004';;
    3) rb='$0008';;
    4) rb='$0010';;
    5) rb='$0020';;
    *)
        return 1;
    esac;
    typeset -g "ROMBit=${rb}"
}

set_vars_shared(){
    typeset -g "SMASGFXLoc=../Graphics"
    typeset -g "MainBrrLoc=../SPC700/Samples/Main"
    typeset -g "RCBrrLoc=../SPC700/Samples/RandomChatter"
    typeset -g "SMASMusicLoc=../SPC700/Music"
    typeset -g "SMB1GFXLoc=../../SMB1/Graphics"
    typeset -g "SMB1MusicLoc=../../SMB1/SPC700/Music"
    typeset -g "SMB2UGFXLoc=../../SMB2U/Graphics"
    typeset -g "SMB2UMusicLoc=../../SMB2U/SPC700/Music"
    typeset -g "SMB3BGGFXLoc=../../SMB3/Graphics/Layer2"
    typeset -g "SMB3GFXLoc=../../SMB3/Graphics"
    typeset -g "SMB3LMusicLoc=../../SMB3/SPC700/Music/Levels"
    typeset -g "SMB3OMusicLoc=../../SMB3/SPC700/Music/Overworld"
    set_rombit ${1}
}

set_vars_smw(){
    typeset -g "SMWCGFXLoc=../../SMW/GFX/SMW_E2"
    typeset -g "SMWUGFXLoc=../../SMW/GFX"
    typeset -g "SMWLMusicLoc=../../SMW/SPC700/Music/Levels"
    typeset -g "SMWOMusicLoc=../../SMW/SPC700/Music/Overworld"
    typeset -g "SMWCMusicLoc=../../SMW/SPC700/Music/Credits"
    typeset -g "SMWBrrLoc=../../SMW/SPC700/Samples"
}

set_rom_ver_vars(){
    echo "get rom version vars..."
    case ${1} in
    0|1|2|3)
        set_vars_shared ${1};;
    4|5)
        set_vars_shared ${1}
        set_vars_smw;;
    *)
        return 1;;
    esac;
}

make_info_blob(){
    fn="$1"
    echo "build info rom file $(basename ${fn})..."
    "${ASAR}" --fix-checksum=off --no-title-check --define ROMVer="$ROMBit" "AssetPointersAndFiles.asm" "${fn}"
}

coerce_pointer_set(){
    v=
    case $1 in
     0) v=0;;
     1) v=6;;
     2) v=12;;
     3) v=18;;
     4) v=24;;
     5) v=30;;
     6) v=36;;
     7) v=42;;
     8) v=48;;
     9) v=54;;
    10) v=60;;
    11) v=66;;
    12) v=72;;
    13) v=78;;
    14) v=84;;
    15) v=90;;
    16) v=96;;
    17) v=102;;
    18) v=108;;
     *) die "bad pointer set id %s" "${1:-[unset]}";;
    esac
    echo $v
}

pointer_set_id_to_name(){
    case $1 in
       0) echo NumOfSets;;
       1) echo SMASGFX;;
       2) echo SMASMusic;;
       3) echo MainBRR;;
       4) echo RCBRR;;
       5) echo SMB1GFX;;
       6) echo SMB1Music;;
       7) echo SMB2UGFX;;
       8) echo SMB2UMusic;;
       9) echo SMB3BGGFX;;
      10) echo SMB3GFX;;
      11) echo SMB3LMusic;;
      12) echo SMB3OMusic;;
      13) echo SMWCGFX;;
      14) echo SMWUGFX;;
      15) echo SMWLMusic;;
      16) echo SMWOMusic;;
      17) echo SMWCMusic;;
      18) echo SMWBRR;;
       *) echo UNKNOWN;
          return 1;;
    esac;
}

get_next_counter(){
    varname=${1}
    set_index=${2}
    iter=${3}
    ptr_rom=${4}
    cat >${tmpasm} <<EOF
    lorom
    org \$008000
    !OnesDigit         = 0
    !TensDigit         = 0
    !HundredsDigit     = 0
    !ThousandsDigit    = 0
    !TensDigitSet      = 0
    !HundredsDigitSet  = 0
    !ThousandsDigitSet = 0
    !Offset #= readfile3("${ptr_rom}", snestopc(\$008000+$(coerce_pointer_set ${set_index})+\$03))
    while !Offset > 0
        !OnesDigit #= !OnesDigit+1
        if !OnesDigit == 10
            !OnesDigit #= 0
            !TensDigit #= !TensDigit+1
            !TensDigitSet #= 1
        endif
        if !TensDigit == 10
            !TensDigit #= 0
            !HundredsDigit #= !HundredsDigit+1
            !HundredsDigitSet #= 1
        endif
        if !HundredsDigit == 10
            !HundredsDigit #= 0
            !ThousandsDigit #= !ThousandsDigit+1
            !ThousandsDigitSet #= 1
        endif
        !Offset #= !Offset-1
    endif
    if !ThousandsDigitSet == 1
    db !ThousandsDigit+\$30
    endif
    if !HundredsDigitSet == 1
    db !HundredsDigit+\$30
    endif
    if !TensDigitSet == 1
    db !TensDigit+\$30
    endif
    db !OnesDigit+\$30
EOF

    truncate -s 0 ${iter}
    if "${ASAR}" --fix-checksum=off --no-title-check ${tmpasm} ${iter}; then
        typeset -g "${varname}=$(cat ${iter})"
    else
        return 1;
    fi;
}

get_file_name(){
    varname=${1}
    file_id=${2}
    ptr_id=${3}

    cat >${tmpasm} <<EOF
    ${memmap}
    org \$008000
    check bankcross off
    !OffsetStart #= snestopc(readfile3("${pointer_rom}", snestopc(readfile3("${pointer_rom}", snestopc(\$008000+$(coerce_pointer_set "${ptr_id}")))+\$06+(${file_id}*\$0C))))
    !OffsetEnd #= snestopc(readfile3("${pointer_rom}", snestopc(readfile3("${pointer_rom}", snestopc(\$008000+$(coerce_pointer_set "${ptr_id}")))+\$09+(${file_id}*\$0C))))
    incbin ${pointer_rom}:(!OffsetStart)-(!OffsetEnd)
EOF
    truncate -s 0 "${wkdir}/fn.txt"
    if ! "${ASAR}" --fix-checksum=off --no-title-check "${tmpasm}" "${wkdir}/fn.txt"; then
        return 1;
    fi;
    typeset -g "${varname}=$(cat ${wkdir}/fn.txt)"
}

patch_smb1gfx_globtiles(){
    echo "patching $(basename ${1})..."
cat >${tmpasm} <<EOF
${memmap}
org \$009FC0
db \$00,\$08,\$08,\$36,\$3E,\$41,\$1C,\$22,\$1C,\$22,\$36,\$49,\$22,\$55,\$00,\$22
db \$08,\$08,\$36,\$36,\$41,\$41,\$22,\$22,\$22,\$22,\$49,\$49,\$55,\$55,\$22,\$22
EOF
"${ASAR}" --fix-checksum=off --no-title-check "${tmpasm}" "${1}"
}

patch_smb3titlegfx_usa(){
    echo "patching $(basename ${1})..."
cat >${tmpasm} <<EOF
${memmap}
org \$008300
db \$00,\$00,\$00,\$00,\$00,\$7E,\$3C,\$42,\$00,\$7E,\$00,\$00,\$00,\$00,\$00,\$00
org \$008500
db \$00,\$F8,\$78,\$84,\$6C,\$92,\$66,\$99,\$66,\$99,\$66,\$99,\$7C,\$82,\$00,\$FC
org \$008520
db \$00,\$E7,\$66,\$99,\$66,\$99,\$66,\$99,\$7E,\$81,\$66,\$99,\$66,\$99,\$00,\$E7
org \$008CA0
db \$00,\$FF,\$66,\$99,\$66,\$99,\$66,\$99,\$66,\$99,\$66,\$99,\$3C,\$42,\$00,\$3C
org \$008F40
db \$00,\$7E,\$3C,\$42,\$18,\$66,\$18,\$24,\$18,\$24,\$18,\$64,\$38,\$44,\$00,\$78
EOF
"${ASAR}" --fix-checksum=off --no-title-check "${tmpasm}" "${1}"
}

patch_smb3_toadhousegfx_usa(){
    echo "patching $(basename ${1})..."
cat >${tmpasm} <<EOF
${memmap}
org \$008420
db \$00,\$64,\$64,\$9A,\$64,\$9A,\$64,\$9A,\$7E,\$81,\$04,\$7A,\$04,\$0A,\$00,\$04
org \$008440
db \$00,\$7C,\$7C,\$82,\$60,\$9C,\$7C,\$82,\$06,\$79,\$06,\$79,\$7C,\$82,\$00,\$7C
org \$008460
db \$00,\$3C,\$3C,\$42,\$60,\$9C,\$7C,\$82,\$66,\$99,\$66,\$99,\$3C,\$42,\$00,\$3C
org \$008480
db \$00,\$7E,\$7E,\$81,\$06,\$79,\$0C,\$12,\$18,\$24,\$30,\$48,\$60,\$90,\$00,\$60
org \$0084A0
db \$00,\$73,\$73,\$8C,\$DB,\$24,\$DB,\$24,\$DB,\$24,\$DB,\$24,\$73,\$8C,\$00,\$73
org \$0084C0
db \$00,\$3C,\$3C,\$42,\$66,\$99,\$66,\$99,\$3E,\$41,\$06,\$39,\$3C,\$42,\$00,\$3C
org \$0084E0
db \$00,\$FF,\$7E,\$81,\$60,\$9E,\$7C,\$82,\$60,\$9C,\$60,\$90,\$60,\$90,\$00,\$F0
org \$008500
db \$00,\$7E,\$3C,\$42,\$18,\$66,\$18,\$24,\$18,\$24,\$18,\$66,\$3C,\$42,\$00,\$7E
org \$008520
db \$00,\$EB,\$6A,\$95,\$6A,\$95,\$6A,\$95,\$6A,\$95,\$6A,\$95,\$3E,\$41,\$00,\$3F
org \$008540
db \$00,\$3C,\$3C,\$42,\$66,\$99,\$66,\$99,\$66,\$99,\$66,\$99,\$3C,\$42,\$00,\$3C
org \$008560
db \$00,\$CC,\$CC,\$32,\$6C,\$92,\$6C,\$92,\$CC,\$32,\$EC,\$13,\$6F,\$90,\$00,\$EF
org \$008580
db \$00,\$3C,\$3C,\$42,\$66,\$99,\$60,\$9F,\$60,\$9F,\$66,\$99,\$3C,\$42,\$00,\$3C
org \$0085A0
db \$00,\$E7,\$62,\$95,\$62,\$95,\$72,\$8D,\$5A,\$A5,\$4E,\$B1,\$46,\$A9,\$00,\$E7
org \$0085C0
db \$00,\$F8,\$78,\$84,\$6C,\$92,\$6C,\$92,\$6C,\$92,\$6C,\$92,\$78,\$84,\$00,\$F8
org \$0085E0
db \$00,\$3C,\$3C,\$42,\$70,\$8E,\$3C,\$42,\$06,\$79,\$66,\$99,\$3C,\$42,\$00,\$3C
EOF
"${ASAR}" --fix-checksum=off --no-title-check "${tmpasm}" "${1}"
}

check_file_hack(){
    fname=${1}
    if ! [[ -f "${1}" ]]; then
        yell "no file ${1}"
        return 1;
    fi;

    case "$(basename "${fname}")" in
    GFX_FG_SMB1_GlobalTiles_USA.bin)
        patch_smb1gfx_globtiles ${fname};;
    GFX_TitleScreen_USA.bin)
        patch_smb3titlegfx_usa ${fname};;
    GFX_BG_ToadHouse_USA.bin)
        patch_smb3_toadhousegfx_usa ${fname};;
    *)
        ;;
    esac
}

extract_file(){
    file_id=${1}
    ptr_id=${2}
    if ! get_file_name FNAME ${1} ${2}; then
        yell "failed to get file for set %d: ix %d" ${ptr_id} ${file_id}
        return 1;
    fi;
    ((VERBOSE == 0)) || echo "extract ${FNAME}..."

cat >${tmpasm} <<EOF
    ${memmap}
    org \$008000
    check bankcross off
    !OffsetStart #= snestopc(readfile3("${pointer_rom}", snestopc(readfile3("${pointer_rom}", snestopc(\$008000+$(coerce_pointer_set "${ptr_id}")))+\$00+(${file_id}*\$0C))))
    !OffsetEnd #= snestopc(readfile3("${pointer_rom}", snestopc(readfile3("${pointer_rom}", snestopc(\$008000+$(coerce_pointer_set "${ptr_id}")))+\$03+(${file_id}*\$0C))))
    incbin ${romname}:(!OffsetStart)-(!OffsetEnd)
EOF
    if ! "${ASAR}" --fix-checksum=off --no-title-check "${tmpasm}" "${wdata}/${FNAME}"; then
        return 1;
    fi;

    if [[ ${SKIP_HACKS} -eq 0 ]]; then
        if ! check_file_hack "${wdata}/${FNAME}"; then
            die "failed to apply patch"
        fi;
    fi;
}

move_files(){
    case $1 in
     1) mv ${wdata}/*.bin "${SMASGFXLoc}";;
     2) mv ${wdata}/*.bin "${SMASMusicLoc}";;
     3) mv ${wdata}/*.brr "${MainBrrLoc}";;
     4) mv ${wdata}/*.brr "${RCBrrLoc}";;
     5) mv ${wdata}/*.bin "${SMB1GFXLoc}";;
     6) mv ${wdata}/*.bin "${SMB1MusicLoc}";;
     7) mv ${wdata}/*.bin "${SMB2UGFXLoc}";;
     8) mv ${wdata}/*.bin "${SMB2UMusicLoc}";;
     9) mv ${wdata}/*.bin "${SMB3BGGFXLoc}";;
    10) mv ${wdata}/*.bin "${SMB3GFXLoc}";;
    11) mv ${wdata}/*.bin "${SMB3LMusicLoc}";;
    12) mv ${wdata}/*.bin "${SMB3OMusicLoc}";;
    13)
        if [[ "${ROMKIND}" -eq 5 ]]; then
            mv ${wdata}/*.lz1 "${SMWCGFXLoc}";
        else
            mv ${wdata}/*.lz2 "${SMWCGFXLoc}";
        fi;
        ;;

    14) mv ${wdata}/*.bin "${SMWUGFXLoc}";;
    15) mv ${wdata}/*.bin "${SMWLMusicLoc}";;
    16) mv ${wdata}/*.bin "${SMWOMusicLoc}";;
    17) mv ${wdata}/*.bin "${SMWCMusicLoc}";;
    18) mv ${wdata}/*.brr "${SMWBrrLoc}";;
     *) yell "bad index %d" ${1}
        return 1;;
    esac;
}

cleanup(){
    rc=$?
    if [[ -d ${wkdir} ]]; then
        if ((rc == 0)); then
            rm -r "${wkdir}"
        else
            echo "preserving work dir ${wkdir}"
        fi;
    fi;
}

# ENTRY
trap cleanup 0

VERBOSE=${VERBOSE:-0}
SKIP_HACKS=${SKIP_HACKS:-0}
romname=${1}
if [[ $# -ne 1 ]]; then
    echo "default to rom SMAS.sfc"
    romname="SMAS.sfc"
fi;

if ! [[ -f "${romname}" ]]; then
    die "%s does not exist or is not a regular file" "${1}"
fi;

if ! find_asar; then
    die "Couldn't find asar"
elif ! get_rom_version ROMKIND "${romname}"; then
    exit 1;
fi;

coerce_rom_version_id ROMKIND
set_rom_ver_vars ${ROMKIND}

wkdir="$(mktemp -d)"
wdata="${wkdir}/data"
mkdir "${wdata}"
tmpasm="${wkdir}/tmp.asm"

echo "use working dir ${wkdir}"

pointer_rom="${wkdir}/ptrs.sfc"
iterator_file="${wkdir}/count.txt"
pointer_set=0

make_info_blob "${pointer_rom}"
if ! get_next_counter N_FILE_SETS "${pointer_set}" "${iterator_file}" "${pointer_rom}"; then
    die "Failed to build %s to get number of file sets" "${iterator_file}"
#else
fi;
((N_FILE_SETS/=6))

echo "$N_FILE_SETS file sets to process"
while ((++pointer_set < ${N_FILE_SETS})); do
    if ! get_next_counter N_FILES "${pointer_set}" "${iterator_file}" "${pointer_rom}"; then
        die "Failed to build %s to get number of files for set %d" "${iterator_file}" "${set_ix}"
    fi;

    if ((N_FILES == 0)); then
        continue;
    fi;

    printf "%s: extracting %d files\n" "$(pointer_set_id_to_name ${pointer_set})" ${N_FILES}
    for ((file_id=0; file_id<${N_FILES}; file_id++)); do
        if ! extract_file ${file_id} ${pointer_set}; then
            die "extraction failed";
        fi;
        if ! move_files ${pointer_set}; then
            die "failed to move files";
        fi;
    done;
done;
echo "Extraction complete"
