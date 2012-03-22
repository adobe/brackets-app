Welcome to Brackets!
====================

You're looking at an early preview of Brackets, a code editor for HTML, CSS 
and JavaScript that's *built* in HTML, CSS and JavaScript. 

We're *very* early in development, so many of the features you would
expect in a code editor are missing, and some existing features might be
incomplete or not as useful as you might like.

Here's what you can do in the current build of Brackets. **We strongly
suggest you read through this before using it.**

Basic usage
-----------

Launch Brackets from the bin/win or bin/mac folder.

Most of the Brackets functionality isn't exposed in the native menus yet;
it's either in keyboard shortcuts or in the menu in the black bar at the top
of the Brackets window. (Did I mention that we're still early in development?)

You can open a file from *File > Open* (Ctrl/Cmd-O) in the in-window Brackets 
menu, or open a folder in the file tree on the left by clicking the Open button. 
It's a good idea to open the root of whatever project you're working on in the 
file tree, since other Brackets features search in the current tree.

Other basic file operations like *File > Save* (Ctrl/Cmd-S), *File > Close*
(Ctrl/Cmd-W), undo/redo (Ctrl/Cmd-Z/Y) and copy/paste should work. Closing a 
file or quitting the app will prompt you to save changes.

Unlike other editors that show open files in tabs, Brackets has a notion of 
the "working set", which is displayed above the file tree. Just clicking on 
files in the file tree doesn't automatically add them to the working set, 
so you can quickly browse through different files without opening them. To 
add a file to the working set, just make an edit in it, or double-click it 
in the file tree.

Brackets currently has color-coding for HTML, JS, CSS, and LESS files. It
doesn't do any code-hinting yet.

If you change a file outside Brackets (e.g. by fetching a newer version
from source control or editing it in another editor at the same time), Brackets
will notice the change and pick it up the next time you switch focus into
Brackets. It doesn't yet detect external changes that happen while you're
still in Brackets--you have to switch out and back in to see these changes.

Inline editors
--------------

One of the goals of Brackets is to make it easy to make quick edits to
different bits of code without having to jump around between files.

Currently, we have a *very early* implementation of this. If you're in an HTML
file, and you put the cursor inside a class or id attribute or a tag name,
you can hit Cmd-E (for "edit"). Brackets will search the CSS files in the file 
tree and show a matching rule in an inline editor. You can make changes in the 
inline editor and save them, then close the editor by hitting Cmd-E again.

This feature is very incomplete and not very useful on real-world sites right now:

* Brackets doesn't take the cascade, tag context, etc. into account, it doesn't
  check to see which CSS files are linked into the current HTML file, and it only
  shows the first rule it finds. So it may very well show a rule other than the one 
  you actually want to edit.
* Changes you make in an inline editor will be mirrored into the main editor for
  the same file, but not vice versa, and are not synced across multiple inline
  editors. So if you have multiple inline editors open on the same style file
  and you make edits in one, the other editors will close. Similarly, if you make
  an edit in the main editor for a style file, any other inline editors pointing
  at that file will close.

(Did I mention that we're still early in development?)

Unofficial features
-------------------

A number of editing features that we've added to Brackets aren't "official"
features (they haven't been implemented as user stories on the backlog, so
don't have final UI, haven't been fully tested, etc.).

* Ctrl/Cmd-F does a find in the current file. After doing a search, you
  can do Cmd-G/Cmd-Shift-G (Mac) or F3/Shift-F3 (Windows) to find next/
  previous.
* Ctrl/Cmd-Shift-F does a find in files. Click on items in the result list
  to jump to them.
* By default, JSLint runs on all JS files and shows its results in a panel
  at the bottom. If your file is clean, you'll see a gold star in the upper
  right corner. JSLint is very picky about formatting. JSLint is very picky 
  about a lot of things. If you want to turn it off, uncheck *Debug > Enable
  JSLint*.
* Ctrl/Cmd-Shift-O brings up a Quick Open field to let you quickly switch
  to another file from the keyboard. You can start typing a filename in the 
  field, then down-arrow or use the mouse to select one of the files that 
  matches. You can also type ":" followed by a number in the field to go to 
  that line in the current file.

Known issues
------------

In addition to the limitations mentioned above, here are some other known
issues. (Did I mention that we're still early in development?)

* The scroll position isn't kept for files that aren't in the working set,
  so if you browse around in the file tree, you'll always start at the top
  of the file.
* Open and Quick Open don't add files to the working set automatically.
* Resizing the window feels sluggish.
* Autoindent on return may not always do what you want, especially for
  multi-line argument lists in JS function calls.
* Touchpad throw scrolling appears jittery due to issues with the mousewheel
  events generated by WebKit (https://bugs.webkit.org/show_bug.cgi?id=81040).

Future features
---------------

Here are some things we're planning to do over the next few sprints:

* Make inline CSS editors actually useful by showing multiple rules and
  being smarter about which ones we show first
* Preview your file in a browser and update it live as you make CSS edits
* Let you set breakpoints in JS directly from Brackets
* Add other kinds of inline editors, like for tweaking CSS gradients
* Add replace functionality (and make the find feature more official)

Feedback
--------

If you find bugs or have feedback on things you'd like to see in Brackets,
please post them as comments on the Wiki page where you downloaded the build.
Eventually we'll have an open bugbase.

Hacking on Brackets
===================

Folder organization
-------------------

Brackets is currently built using a thin native app shell around an HTML/JS/CSS
app. If you pull the repos as described below, or look in the contents of the ZIP
file, you'll see that the main app binaries are in the bin/ folder, but the
actual HTML/JS/CSS files that implement the main app are in the brackets/
subfolder. The src/ folder is just the source for the native app shell.

Getting the source
------------------

Brackets is currently hosted in two github repos: the 
[brackets-app repo](http://github.com/adobe/brackets-app), which contains
the native app shell, and the [brackets repo](http://github.com/adobe/brackets), 
which contains the HTML/JS/CSS code. The brackets-app repo contains the brackets
repo as a submodule. (These repos are currently private, so you'll need to
contact us for access.)

In addition to pulling brackets-app from github, you'll need to also grab submodule
references by the Brackets application. To do so, first make sure you have SSH 
access to github (since the submodules are referenced via a git: URL rather than 
https). Then run the following command in the root of your brackets-app repo:

    git submodule update --init --recursive
    
See [Pro Git section 6.6](http://progit.org/book/ch6-6.html) for some caveats 
when working with submodules.

To test if everything is working, run bin/mac/Brackets.app or bin/win/Brackets.exe. 
You should see the brackets interface. 

Here are instructions for modifying the app shell on Mac (Win instructions coming
soon):

To modify the application shell code, load src/mac/Brackets.xcodeproj into 
XCode 4.1 (or newer). 

There are three main build targets: 

1. Brackets CEF Debug - this is a full debug build and is **really** slow. 
   This target should only be used if you need breakpoint debugging.
2. Brackets Development - this is a "release development" build. It's much 
   faster, but you can't set breakpoints.
3. Brackets Archive - this target does a full release build and copies the 
   build to the bin/mac directory. This target MUST be built before checking in any changes to the shell application.

**NOTE:** Before you build anything, you need to make a couple changes to the 
build schemes. This only needs to be done once since these setting will persist 
when you quit xcode.

1. Click the combobox at the top that says "Brackets Archive".
2. Select "Edit Scheme..." from the dropdown.
3. In the window that opens, select "Run Brackets.app" on the left hand list
4. In the right pane, select "Release" for Build Configuration
5. Click OK to close the window
6. Select "Brackets Development" from the dropdown
7. Repeat steps 1-5 for the Brackets Development scheme

**IMPORTANT:** If you make changes to the application shell, you **MUST** build 
the Brackets Archive target. This will ensure a updated Release build is checked 
in to /bin/mac.

Useful tools
------------

Because Brackets is built in HTML/JS/CSS, we've actually started using Brackets
itself to edit its own source code. It's pretty fun!

If you use Brackets to edit Brackets, you can quickly reload the app itself by 
choosing *View > Refresh* from the native menu (not the in-Brackets menu).
You can also bring up the Chrome developer tools on the Brackets window using
*View > Show Developer Tools*.

You can open a second Brackets window from the *Debug > New Window* item in
the in-Brackets menu (not the native menu). This is nice because it means you
can use a stable Brackets in one window to edit your code, and then reload the
app in the second window to see if your changes worked. You can bring up the
developer tools on the second window, too.

You can use *Debug > Run Tests* to run our unit test suite, and *Debug >
Show Perf Data* to show some rudimentary performance info.
