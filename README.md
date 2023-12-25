# MAAD Attack Framework
![MAAD_Logo](images/MAAD_AF.png)                                                                     
        
MAAD-AF is an open-source cloud attack tool for Microsoft 365 & Entra ID(Azure AD) environments.

MAAD-AF offers simple, fast and effective security testing. Validate Microsoft cloud controls and test detection & response capabilities with a virutally zero-setup process, complete with a fully interactive workflow for executing emulated attacks. 

MAAD-AF is developed natively in PowerShell.

## Usage
1. Clone or download MAAD-AF from GitHub
2. Start PowerShell as Admin and navigate to MAAD-AF directory
```
> git clone https://github.com/vectra-ai-research/MAAD-AF.git
> cd /MAAD-AF
```
3. Launch MAAD-AF
```
> MAAD_Attack.ps1 
# Launch and bypass dependency checks
> MAAD_Attack.ps1 -ForceBypassDependencyCheck
```

## Requirements
 1. Windows host
 2. PowerShell 5.1

## Features
- Attack emulation tool
- Fully interactive (no-commands) workflow
- Zero-setup deployment
- Ability to revert actions for post-testing cleanup
- Leverage MITRE ATT&CK
- Emulate post-compromise attack techniques
- Attack techniques for Entra ID (Azure AD)
- Attack techniques for Exchange Online
- Attack techniques for Teams
- Attack techniques for SharePoint
- Attack techniques for eDiscovery

## MAAD-AF Techniques
- Recon data from various Microsoft services
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
- [More...](https://openrec0n.github.io/maad-af-docs/)

## Contribute
 - Thanks for considering contributing to MAAD-AF! Your contributions will help make MAAD-AF better.
 - Submit your PR to the main branch.
 - Submit bugs & issues directly to [GitHub Issues](https://github.com/vectra-ai-research/MAAD-AF/issues)
 - Share ideas in [GitHub Discussions](https://github.com/vectra-ai-research/MAAD-AF/discussions)

## Contact
If you found MAAD-AF useful, want to share an interesting use-case or idea - reach out & share them
 - Maintainer : [Arpan Sarkar](https://www.linkedin.com/in/arpan-sarkar/)
 - Email : [MAAD-AF@vectra.ai](mailto:maad-af@vectra.ai)