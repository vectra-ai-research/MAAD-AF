# MAAD Attack Framework
![MAAD_Logo](images/MAAD_AF.png)                                                                     
        
MAAD-AF is an open-source cloud attack tool for Microsoft 365 & Entra ID(Azure AD) environments.

MAAD-AF is designed to make cloud security testing simple, fast and effective. Through its virtually no-setup requirement and easy to use interactive attack modules, security teams can test their security controls, detection and response capabilities easily and swiftly. 

MAAD-AF is completely developed in PowerShell.

## Features
- Post-compromise techniques
- Simple interactive use
- Revert actions for clean testing
- Virtually no-setup requirements
- Attack modules for Entra ID (Azure AD)
- Attack modules for Exchange
- Attack modules for Teams
- Attack modules for SharePoint
- Attack modules for eDiscovery

### MAAD-AF Modules
- Recon data from various services & data stores
- Backdoor Account Setup
- Trusted Network Modification
- Mailbox Audit Bypass
- Disable Anti-Phishing in Exchange
- Mailbox Deletion Rule Setup
- Exfiltration through Mail Forwarding
- Gain User Mailbox Access
- Setup External Teams Access
- Exploit Cross Tenant Synchronization 
- eDiscovery exploitation for data recon & exfil
- Bruteforce credentials
- MFA Manipulation
- User Account Deletion
- SharePoint exploitation for data recon & exfil
- Many more...

## Getting Started
### Plug & Play - It's that easy!
 1. Clone or download the MAAD-AF github repo to your windows host
 2. Open PowerShell as Administrator 
 3. Navigate to the local MAAD-AF directory 
 4. Run MAAD_Attack.ps1 
```
> git clone https://github.com/vectra-ai-research/MAAD-AF.git
> cd /MAAD-AF
> ./MAAD_Attack.ps1
```

### Requirements
1. Internet accessible Windows host.
2. PowerShell (version 5) with local administrator permissions.
3. All external powershell modules required will be installed automatically.

## Contribute
 - Thank you for considering contributing to MAAD-AF!  
 - Your contributions will help make MAAD-AF better.
 - Join the mission to make security testing simple, fast and effective.
 - Submit a PR to the main branch to contribute to MAAD-AF.

### Report Bugs
 - Submit bugs or other issues related to the tool directly in the "Issues" section

### Request Features
 - Share those great ideas. Submit new features by submitting a PR or sharing them in GitHub Discussions. 

## Contact
- If you found this tool useful, want to share an interesting use-case, bring issues to attention, whatever the reason - share them. You can email at: maad-af@vectra.ai or post it in Discussions on GitHub.
