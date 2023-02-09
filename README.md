# MAAD Attack Framework
![MAAD_Logo](images/MAAD_AF.png)                                                                     
        
MAAD-AF is an open-source cloud attack tool developed for testing security of Microsoft 365 & Azure AD environments through adversary emulation. MAAD-AF provides security practitioners easy to use attack modules to exploit configurations across different M365/AzureAD cloud-based tools & services.

MAAD-AF is designed to make cloud security testing simple, fast and effective. Through its virtually no-setup requirement and easy to use interactive attack modules, security teams can test their security controls, detection and response capabilities easily and swiftly. 

## Features
- Pre & Post-compromise techniques
- Simple interactive use
- Virtually no-setup requirements
- Attack modules for Azure AD
- Attack modules for Exchange
- Attack modules for Teams
- Attack modules for SharePoint
- Attack modules for eDiscovery

### MAAD-AF Attack Modules
- Azure AD External Recon (Includes sub-modules)
- Azure AD Internal Recon (Includes sub-modules)
- Backdoor Account Setup
- Trusted Network Modification
- Disable Mailbox Auditing
- Disable Anti-Phishing
- Mailbox Deletion Rule Setup
- Exfiltration through Mailbox Forwarding
- Gain User Mailbox Access
- External Teams Access Setup (Includes sub-modules)
- eDiscovery exploitation (Includes sub-modules)
- Bruteforce
- MFA Manipulation
- User Account Deletion
- SharePoint exploitation (Includes sub-modules)

## Getting Started
### Plug & Play - It's that easy!
 1. Clone or download the MAAD-AF github repo to your windows host
 2. Open PowerShell as Administrator 
 3. Navigate to the local MAAD-AF directory 
	 `(cd /MAAD-Attack-Framework)`
 4. Run MAAD_Attack.ps1 
	 `(./MAAD_Attack.ps1)`

### Requirements
1. Internet accessible Windows host
2. PowerShell (version 5 or later) terminal as Administrator
3. The following powershell modules are required and will be installed automatically:
- Az, AzureAd, MSOnline, ExchangeOnlineManagement, MicrosoftTeams, AzureADPreview, AADInternals, Microsoft.Online.SharePoint.PowerShell, PnP.PowerShell

Note: A 'Global Admin' privilege is required to leverage full capabilities of modules in MAAD-AF

### Limitations
- MAAD-AF is currently only fully supported on Windows OS

## Contribute
 - Thank you for considering contributing to MAAD-AF!  
 - Your contributions will help make MAAD-AF better.
 - Join the mission to make security testing simple, fast and effective.
 - There's ongoing efforts to make the source code more modular to enable easier contributions.
 - Continue monitoring this space for updates on how you can easily incorporate new attack modules into MAAD-AF.

### Add Custom Modules
 - Everyone is encouraged to come up with new attack modules that can be added to the MAAD-AF Library. 
 - Attack modules are functions that leverage access & privileges established by MAAD-AF to exploit configuration flaws in Microsoft services.

### Report Bugs
 - Submit bugs or other issues related to the tool directly in the "Issues" section

### Request Features
 - Share those great ideas. Submit new features to add to the MAAD-AFs functionality. 

## Contact
- If you found this tool useful, want to share an interesting use-case, bring issues to attention, whatever the reason - I would love to hear from you. You can contact at: maad-af@vectra.ai