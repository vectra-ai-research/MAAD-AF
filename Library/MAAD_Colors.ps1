### Color definitions.
### These can be referenced where color formatting is desired.  
###
### Instead of:
### Write-Host "Lorem ipsum" -ForegroundColor Yellow -BackgroundColor Black
###
### Use instead:
### Write-Host "Lorem ipsum" @fg_yellow @bg_black
###

# Foreground colors
$fg_black = @{ ForegroundColor = "Black" }
$fg_blue = @{ ForegroundColor = "Blue" }
$fg_darkblue = @{ ForegroundColor = "DarkBlue" }
$fg_cyan = @{ ForegroundColor = "Cyan" }
$fg_darkcyan = @{ ForegroundColor = "DarkCyan" }
$fg_green = @{ ForegroundColor = "Green" }
$fg_darkgreen = @{ ForegroundColor = "DarkGreen" }
$fg_gray = @{ ForegroundColor = "Gray" }
$fg_darkgray = @{ ForegroundColor = "DarkGray" }
$fg_magenta = @{ ForegroundColor = "Magenta" }
$fg_darkmagents = @{ ForegroundColor = "DarkMagenta" }
$fg_red = @{ ForegroundColor = "Red" }
$fg_darkred = @{ ForegroundColor = "DarkRed" }
$fg_yellow = @{ ForegroundColor = "Yellow" }
$fg_darkyellow = @{ ForegroundColor = "DarkYellow" }

# Background colors
$bg_black = @{ BackgroundColor = "Black" }
$bg_blue = @{ BackgroundColor = "Blue" }
$bg_darkblue = @{ BackgroundColor = "DarkBlue" }
$bg_cyan = @{ BackgroundColor = "Cyan" }
$bg_darkcyan = @{ BackgroundColor = "DarkCyan" }
$bg_green = @{ BackgroundColor = "Green" }
$bg_darkgreen = @{ BackgroundColor = "DarkGreen" }
$bg_gray = @{ BackgroundColor = "Gray" }
$bg_darkgray = @{ BackgroundColor = "DarkGray" }
$bg_magenta = @{ BackgroundColor = "Magenta" }
$bg_darkmagents = @{ BackgroundColor = "DarkMagenta" }
$bg_red = @{ BackgroundColor = "Red" }
$bg_darkred = @{ BackgroundColor = "DarkRed" }
$bg_yellow = @{ BackgroundColor = "Yellow" }
$bg_darkyellow = @{ BackgroundColor = "DarkYellow" }