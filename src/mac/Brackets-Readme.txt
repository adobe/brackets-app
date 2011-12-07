This is a mac shell application for running Brackets on the desktop. This app is a modified version of the "cefclient" sample application included with the chromium embedded framework. The original source is available here:
http://code.google.com/p/chromiumembedded/

Modifications to the app include -

Remove:
* button bar at top
* "Tests" menu
* test classes

Add:
* View menu items: Refresh, Show Dev Tools (both only work on the main window)
* Implementations for alert, confirm and prompt (see client_handler_mac.mm for OnJSAlert, OnJSConfirm and OnJSPrompt)
* Scaffolding for native <--> javscript bridge

Native <--> JavaScript bridge
The native-javascript bridge lives in brackets_extensions.mm/.h. The InitBracketsExtensions() method defines the JavaScript classes. The BracketsExtensionsHandler.Execute method is called for all native functions references from the JavaScript inside InitBracketsExtensions.
