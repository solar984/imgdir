imgdir
======

Shell script for creating a gallery of photos

Setup
-----

* Put `imgdir2.sh` somewhere and mark it executable.  Something like `chmod 755 imgdir2.sh` will do it.
* Put the static files (from the static directory) somewhere on a webserver.  This can be an S3 bucket or whatever you want, they're just static files that need to be served.  Use an HTTPS URL if you are going to use HTTPS for the photo galleries.  Test to make sure you can load the files through a browser and make note of the URL.
* Adjust the `staticbaseurl` line to your static URL location, including a trailing slash.  You could just use CDN versions of all these files too but then you're dependent on the internet and the CDN.  I recommend putting the static files in a sub directory of your gallery site so your gallery is self contained.

Usage
-----
* Put your .jpg files into a directory, for example `~/images/my-vacation` so you end up with files like `~/images/my-vacation/image1.jpg`
* Go into the directory with the jpg files and run `imgdir2.sh`

        cd ~/images/my-vacation
        ~/imgdir2.sh
        
* There will be an `index.html` in the current directory.  All of the thumbnails and individual pages are created in a `.t` subdirectory.  If you need to regenerate them, just `rm -r .t` and run the script again.
* If you're simply adding images to the directory you don't have to delete the existing thumbnails and you can just run the script again.  It will only process the new items.
