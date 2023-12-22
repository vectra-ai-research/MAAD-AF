function MAADInitialization {
    #Clear powershell window
    Clear-Host
    #Set window title
    $host.UI.RawUI.WindowTitle = "MAAD Attack Framework"

    #Display MAAD-AF art
    DisplayCentre "MMMM     AMMM        AMMMM        AMMMM MMMMMMMMD               AMMMM MMMMMMMMMM " "Yellow"
    DisplayCentre "MMMMM   AMMMM       AMMMMM       AMMMMM MMM    MMM             AMMMMM MMM        " "Yellow"
    DisplayCentre "MMMMMM.AMMMMM      AMMAMMM      AMMAMMM MMM    MMM            AMMAMMM MMM        " "Yellow"
    DisplayCentre "MMMYMMMMMAMMM     AMMA MMM     AMMA MMM MMM    MMM           AMMA MMM MMMMMMM    " "Yellow"
    DisplayCentre "MMM YMMMA MMM    AMMA  MMM    AMMA  MMM MMM    MMM          AMMA  MMM MMM        " "Yellow"
    DisplayCentre "MMM  YMA  MMM   AMMA   MMM   AMMA   MMM MMM    MMM         AMMA   MMM MMM        " "Yellow"
    DisplayCentre "MMM   Y   MMM  AMMMMMMMMMM  AMMMMMMMMMM MMM   AMMA        AMMMMMMMMMM MMM        " "Yellow"
    DisplayCentre "MMM       MMM AMMA     MMM AMMA     MMM MMMMMMMAD        AMMA     MMM MMM        " "Yellow"
    DisplayCentre "v_3.0" "Gray"
    DisplayCentre "Created by Arpan Sarkar (@openrec0n)" "Gray"
    Write-Host ""
    DisplayCentre "Simple, Fast & Effective Security Testing" "White" 
    Write-Host ""
    Start-Sleep -Seconds 2
}