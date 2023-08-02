#Install NPCAP
iwr -uri https://nmap.org/npcap/dist/npcap-0.86.exe -OutFile npcap-0.86.exe
./npcap-0.86.exe

#Install Wireshark
iwr -uri https://www.wireshark.org/download/win64/all-versions/Wireshark-win64-4.0.7.msi -OutFile .\Wireshark-win64-4.0.7.msi
.\Wireshark-win64-4.0.7.msi /qb