;--------------------------------
; FileBot NSIS installer script
;--------------------------------

!define PRODUCT_PROPER_NAME                "FileBot"
!define INSTALLER_EXE_NAME                 "FileBot-setup.exe"
!define WINDOWS_10                         "Windows 10"


!define OPTION_USE_MUI_2


;--------------------------------
; Installer Configuration
;--------------------------------

; Request admin privileges for Windows Vista, 7.
RequestExecutionLevel admin

; Name (shown in various places in the installer UI)
Name "${PRODUCT_PROPER_NAME}"

; Output file generated by NSIS compiler
OutFile "${INSTALLER_EXE_NAME}"

; Use lzma compression
SetCompressor lzma

; Optimize Data Block
SetDatablockOptimize on

; Restore last write datestamp of files
; SetDateSave on

; Show installation details
ShowInstDetails   show
ShowUnInstDetails show


;--------------------------------
; Includes
;--------------------------------
!include "MUI2.nsh"
!include "x64.nsh"

!include "StrFunc.nsh"
${StrLoc}


;--------------------------------
; Modern UI Configuration
;--------------------------------

; MUI Settings
!define MUI_ABORTWARNING

; MUI Settings / Icons
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\orange-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\orange-uninstall.ico"

; MUI Settings / Header
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Header\orange-r.bmp"
!define MUI_HEADERIMAGE_UNBITMAP "${NSISDIR}\Contrib\Graphics\Header\orange-uninstall-r.bmp"

; MUI Settings / Wizard
!define MUI_WELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\orange.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\orange-uninstall.bmp"


;--------------------------------
; Installer pages
;--------------------------------

; Welcome page
!insertmacro MUI_PAGE_WELCOME

; End user license agreement
!insertmacro MUI_PAGE_LICENSE "FileBot_EULA.txt"

; Perform installation
!insertmacro MUI_PAGE_INSTFILES

; Finish page
!insertmacro MUI_PAGE_FINISH



;--------------------------------
; Language support
;--------------------------------

!insertmacro MUI_LANGUAGE "English"
LangString Section_Name_MainProduct    ${LANG_ENGLISH} "${PRODUCT_PROPER_NAME}"


;---------------------------
; Install sections
;---------------------------
Var WINDOWS_EDITION
Var WINDOWS_EDITION_INDEX
Var EXPECTED_HASH
Var ACTUAL_HASH
Var MSI_STATUS


Section MAIN
	ReadRegStr "$WINDOWS_EDITION" HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "ProductName"
	DetailPrint "FileBot for $WINDOWS_EDITION"

	${StrLoc} $WINDOWS_EDITION_INDEX "$WINDOWS_EDITION" "${WINDOWS_10}" ">"
	${if} $WINDOWS_EDITION_INDEX == 0
		ExecShell "open" "ms-windows-store://pdp/?productid=9NBLGGH52T9X&cid=NSIS&referrer=NSIS"
		DetailPrint "The legacy installer for Windows 7 and 8 cannot be used on Windows 10 or higher."
		DetailPrint "Please purchase FileBot on the Windows Store."
		Abort
	${endif}


	DetailPrint "Downloading latest version..."

	${if} ${RunningX64}
		inetc::get /RESUME /NOCANCEL /USERAGENT "nsis" /CAPTION "Downloading FileBot (64-bit)" "https://app.filebot.net/download.php?type=msi&arch=x64" "$PLUGINSDIR\FileBot.msi" /END
		inetc::get /TOSTACK /SILENT /NOCANCEL /USERAGENT "nsis" /CAPTION "FileBot MSI Installer Hash (64-bit)" "https://raw.githubusercontent.com/filebot/filebot-installer/master/hash/x64.msi.sha256" /END
	${else}
		inetc::get /RESUME /NOCANCEL /USERAGENT "nsis" /CAPTION "Downloading FileBot (32-bit)" "https://app.filebot.net/download.php?type=msi&arch=x86" "$PLUGINSDIR\FileBot.msi" /END
		inetc::get /TOSTACK /SILENT /NOCANCEL /USERAGENT "nsis" /CAPTION "FileBot MSI Installer Hash (32-bit)" "https://raw.githubusercontent.com/filebot/filebot-installer/master/hash/x86.msi.sha256" /END
	${endif}

	Pop $EXPECTED_HASH	# OK
	Pop $EXPECTED_HASH	# b6d27547d7bc720cc97f2e0c6aa6127f7d9ad2a406d473989f584b339926626d

	Crypto::HashFile "SHA2-256" "$PLUGINSDIR\FileBot.msi"
	Pop $ACTUAL_HASH

	StrCmp $ACTUAL_HASH $EXPECTED_HASH 0 +3
	DetailPrint "SHA-256 hash verified."
	Goto +5
	DetailPrint "SHA-256 hash: $ACTUAL_HASH"
	DetailPrint "Expected SHA-256 hash: $EXPECTED_HASH"
	DetailPrint "Failed to verify SHA-256 hash."
	Abort

	DetailPrint "Installing latest version..."
	nsExec::Exec `msiexec /passive /norestart /i "$PLUGINSDIR\FileBot.msi"`
	Pop $MSI_STATUS

	${if} $MSI_STATUS == "0"
		DetailPrint "Optimizing..."
		nsExec::ExecToLog `"C:\Program Files\FileBot\filebot.exe" -script "g:println Settings.applicationIdentifier; println 'JRE: '+Settings.javaRuntimeIdentifier; println 'JVM: '+(com.sun.jna.Platform.is64Bit() ? 64 : 32)+'-bit '+System.getProperty('java.vm.name'); java.util.prefs.Preferences.userRoot(); CacheManager.getInstance().clearAll(); MediaDetection.warmupCachedResources();" --log OFF`
		ExecShell "open" "http://www.filebot.net/getting-started/index.html"
		ExecShell "open" "http://www.filebot.net/manual.html"
		DetailPrint "Done."
	${else}
		DetailPrint "msiexec error $MSI_STATUS"
		ExecShell "open" "http://www.filebot.net/files/"
		${if} ${RunningX64}
			DetailPrint "Installation failed. Please download the x64 msi package manually."
		${else}
			DetailPrint "Installation failed. Please download the x86 msi package manually."
		${endif}
		Abort
	${endif}
SectionEnd
