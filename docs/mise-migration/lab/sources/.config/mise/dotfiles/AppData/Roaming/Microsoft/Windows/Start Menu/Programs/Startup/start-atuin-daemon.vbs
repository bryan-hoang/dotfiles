' Starts the Atuin daemon hidden at logon (E163). The Windows application
' module (unit atuin_daemon) copies this file read-only into the Startup
' folder once atuin resolves on the persistent login PATH.
CreateObject("WScript.Shell").Run "atuin daemon", 0, False
