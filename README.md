This is a fork of Yoshifanatic's SMAS+W disassembly to allow Linux users to directly extract the SMAS+W ROM assets & assemble the standalone SMB3 ROM without using Wine or Bottles.


**Only SMB3 can be fully assembled, not the whole SMAS+W or the other standalone games!** Support for the other game's batch files may come sometime in the future, but my shell scripting knowledge is personally very limited!
If something doesn't work as intended, please lemme know!

**How to Use?**
1. First, download this fork & drag the whole 'SMW-SMAS-SMASW-Disassembly-main' folder somewhere you like.
2. Then get a clean, unheadered SMAS+W .sfc ROM, rename it to 'SMAS.sfc', and drag it to 'SMAS/AsarScripts'.
3. Now go to the 'Global' folder and right-click on the file 'Asar'. Under 'Properties/Permissions', enable 'Allow executing file as program'.
4. While in 'AsarScripts' open the Linux terminal, and do 'bash extract_assets_linux.sh' to extract the ROM's assets. Make sure to follow the instructions from there!
5. Afterwards, go to the 'SMB3' folder and there, open the terminal again and do 'bash assemble_smb3_linux.sh'. Make sure to follow the instructions from there!
6. A fully-playable standalone ROM called 'Super Mario Bros. 3 U.sfc' will be created!
7. Enjoy!

**Special Thanks**
- Yoshifanantic1 for the original disassembly
- Sir Walrus from SnesLab (formerly Alcaro from SMW Central) for the main support and for the Asar executable
- meatloaf & MarioFanGamer from SnesLab (also from SMW Central) for the additional support
- **You** for benefitting from this disassembly!
