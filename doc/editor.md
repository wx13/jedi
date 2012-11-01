editor.rb is a text editor writen in ruby for the unix console. The
project is hosted on [github](https://github.com/wx13/editor).

Why another text editor? Because I couldn't find any that satisfy the
all of the following:
1. Zero install
2. Easy to hack
3. Text UI


Some Features
=============

Portable
--------

The code is a self-contained, single file of ruby code.  It should run
anywhere ruby is installed.  It calls only built-in libraries.  You can
literally just plop it somewhere and call `ruby editor.rb`.  By default
it will not store any configuration files anywhere. You can give it a
location to store configuration and history files on the command line.
See the user manual for more details.


Scriptable and extendable
-------------------------

Because Ruby supports metaprogramming, extending the capabilities is
easy.  In fact, configuration, modification, and extension are all the
same. There are 2 ways to do it.

1. On the fly.
   Enter ruby commands directly into the editor (good for quick
   one-liners) or call a ruby script file from within the editor.
2. On start-up.
   Use the -s flag to call a ruby script at startup.  This is
   useful for having an external configuration file.


Four cursor modes
-----------------

1. row mode: highlight from mark to cursor along the text
   - Good for cutting and pasting blocks of text.
2. column mode: highlight one skinny column.
   - Good for inserting or deleting aligned text.
3. nmuloc mode: same as column mode, but measured from the end
   of the line.
   - Good for inserting or deleting text at or near the end of the lines.
4. multi-cursor mode: place cursor at multiple arbitrary points within the text.
   - Good for inserting the same text in multiple locations.


Text folding/hiding
-------------------

Can fold any contiguous lines of text, and can move, cut, copy folded
lines just like regular lines.  Additionally, the editor can fold all
blocks of text that match a start and end pattern. This is useful for
folding all functions or classes, so that  you can focus on editing
just one or two of them.


Split-screen mode
-----------------

Put any number of buffers on the same screen, with either vertial or
horizontal layout. You can even edit the same file in two different
screens.  This is useful for working on different parts of a file at
the same time.


Indentation facade
------------------

Say you like to use tabs to indent your code, but the code you are
working with uses spaces (or any other scenario).  Indentation facade
converts one indentation string to another, sets the tab key to insert
the new indentation string, and silently keeps track of the facade for
saving and diffing.

