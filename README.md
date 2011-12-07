Overview
========

This repository is for the Brackets desktop application shell. The core editor, written in HTML/CSS/JavaScript, lives in a [separate repo](http://github.com/adobe/brackets). This repository includes the core editor as a submodule. 

Getting started
===============

In addition to pulling the source from github, you'll need to also grab submodules references by the Brackets application. To do so, first make sure you have SSH access to github (since the submodules are referenced via a git: URL rather than https). Then run the following command in the root of your brackets-app repo:

    git submodule update --init --recursive
    
See [Pro Git section 6.6](http://progit.org/book/ch6-6.html) for some caveats when working with submodules.

To test if everything is working, run bin/mac/Brackets.app. You should see the brackets interface. Note: this app is currently Mac only.

To modify the application shell code, load src/mac/Brackets.xcodeproj into XCode 4.1 (or newer). There are three main build targets: 

1. Brackets CEF Debug - this is a full debug build and is **really** slow. This target should only be used if you need breakpoint debugging.
2. Brackets Development - this is a "release development" build. It's much faster, but you can't set breakpoints.
3. Brackets Archive - this target does a full release build and copies the build to the bin/mac directory. This target MUST be built before checking in any changes to the shell application.

**IMPORTANT:** If you make changes to the application shell, you **MUST** build the Brackets Archive target. This will ensure a updated Release build is checked in to /bin/mac.

