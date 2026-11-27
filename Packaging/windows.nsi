Unicode True
!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"
!ifndef VERSION
  !define VERSION "2.1.0"
!endif
!ifndef INPUT
  !error "INPUT must name the folder containing the game"
!endif
!ifndef OUTPUT
  !error "OUTPUT must name the installer"
!endif
Name "SPOONFUL"
OutFile "${OUTPUT}"
InstallDir "$LOCALAPPDATA\Programs\SPOONFUL"
RequestExecutionLevel user
SetCompressor /SOLID lzma
VIProductVersion "${VERSION}.0"
VIAddVersionKey /LANG=1036 "ProductName" "SPOONFUL"
VIAddVersionKey /LANG=1036 "FileDescription" "SPOONFUL · Installation"
VIAddVersionKey /LANG=1036 "FileVersion" "${VERSION}"
VIAddVersionKey /LANG=1036 "LegalCopyright" "SPOONFUL"
!define MUI_ICON "spoonful.ico"
!define MUI_UNICON "spoonful.ico"
!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\SPOONFUL.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Prendre la cuillère et jouer"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "French"
!define ARP "Software\Microsoft\Windows\CurrentVersion\Uninstall\SPOONFUL"

Section "SPOONFUL"
  SetShellVarContext current
  SetOutPath "$INSTDIR"
  File "${INPUT}/SPOONFUL.exe"
  File "${INPUT}/SPOONFUL.pck"
  File "spoonful.ico"
  WriteUninstaller "$INSTDIR\Desinstaller.exe"
  CreateShortcut "$SMPROGRAMS\SPOONFUL.lnk" "$INSTDIR\SPOONFUL.exe" "" "$INSTDIR\spoonful.ico"
  WriteRegStr HKCU "${ARP}" "DisplayName" "SPOONFUL"
  WriteRegStr HKCU "${ARP}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "${ARP}" "Publisher" "Fares1212"
  WriteRegStr HKCU "${ARP}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "${ARP}" "DisplayIcon" "$INSTDIR\spoonful.ico"
  WriteRegStr HKCU "${ARP}" "UninstallString" '$\"$INSTDIR\Desinstaller.exe$\"'
  WriteRegDWORD HKCU "${ARP}" "NoModify" 1
  WriteRegDWORD HKCU "${ARP}" "NoRepair" 1
SectionEnd

Section "Uninstall"
  SetShellVarContext current
  Delete "$SMPROGRAMS\SPOONFUL.lnk"
  Delete "$INSTDIR\SPOONFUL.exe"
  Delete "$INSTDIR\SPOONFUL.pck"
  Delete "$INSTDIR\spoonful.ico"
  Delete "$INSTDIR\Desinstaller.exe"
  RMDir "$INSTDIR"
  DeleteRegKey HKCU "${ARP}"
SectionEnd
