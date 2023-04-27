$Global:MAAD_AF= @"

                      MMMM     AMMM        AMMMM        AMMMM MMMMMMMMD               AMMMM MMMMMMMMMM 
                      MMMMM   AMMMM       AMMMMM       AMMMMM MMM    MMM             AMMMMM MMM        
                      MMMMMM.AMMMMM      AMMAMMM      AMMAMMM MMM    MMM            AMMAMMM MMM        
                      MMMYMMMMMAMMM     AMMA MMM     AMMA MMM MMM    MMM           AMMA MMM MMMMMMM    
                      MMM YMMMA MMM    AMMA  MMM    AMMA  MMM MMM    MMM          AMMA  MMM MMM        
                      MMM  YMA  MMM   AMMA   MMM   AMMA   MMM MMM    MMM         AMMA   MMM MMM        
                      MMM   Y   MMM  AMMMMMMMMMM  AMMMMMMMMMM MMM   AMMA        AMMMMMMMMMM MMM        
                      MMM       MMM AMMA     MMM AMMA     MMM MMMMMMMAD        AMMA     MMM MMM        
"@

function MAADInitialization {
$host.UI.RawUI.WindowTitle = "MAAD Attack Framework"
Write-Host $Global:MAAD_AF @fg_yellow
Write-Host "                                            Created by Arpan Sarkar (@openrec0n)`n" @fg_gray

#Initiation disclaimer
Write-Host "                                              Welcome to MAAD Attack Framework`n                                 Attack Tool for simple, fast & effective security testing`n" 
$null = Read-Host "By using MAAD-AF you agree to use it for educational purposes or authorized security testing only. `nPress 'Enter' to continue or hit [Ctrl+C] to exit..."
}