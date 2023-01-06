Bismut
======
This is a hierarchical color tracker. Like a traditional bug/task tracker but with multicolored hierarchical items so your whole project looks a bit like a bismuth oxide, and you can see its health immediately just by looking at the tasks at hand. If you get the concept but want to suggest a feature or a bug fix, contact me at: akalenuk@gmail.ua.

How to run
----------
The source code is licensed under Apache 2.0. TL&DR: you do whatever you want, I don't take any responsibility.

This is a «Nitrogen» site. To run your own instance, download Nitrogen, put the sources into the site/ folder, and run the Nitrogen node by running

    bin/nitrogen console

The site will appear at

    http://127.0.0.1:8000

Disclaimer
----------
This is a prototype, a proof of concept. It uses a file system as a key/value storage and even keeps passwords unhashed and unsalted. If you want to use it for anything other than toying with, at the very minimum, you have to patch these things up first.
