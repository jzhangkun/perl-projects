# perl-cgi
CGI scripting

# Sample CGI
## Native CGI scripts
[hello.pl](https://github.com/jzhangkun/perl-cgi/blob/master/cgi-bin/hello.cgi)
[printenv.pl](https://github.com/jzhangkun/perl-cgi/blob/master/cgi-bin/printenv.cgi)

## With CGI module


# Apache Configuration
recommended [Toturial from Apache](https://httpd.apache.org/docs/2.4/howto/cgi.html)
checking points:
* LoadModule for mod_cgi.so/mod_cgid.so
* ScriptAlias tells Apache that a particular directory is set aside for CGI programs
* AddHandler 
* All output from your CGI program must be preceded by a MIME-type header. like, "Content-type: text/html"
* Change File permissions to be 755 executable

# Q&A
## Mixing POST and URL Parameters
```perl
$color = $query->url_param('color');
```
It is possible for a script to receive CGI parameters in the URL as well as in the fill-out form by creating a form that POSTs to a URL containing a query string (a "?" mark followed by arguments). The param() method will always return the contents of the POSTed fill-out form, ignoring the URL's query string. To retrieve URL parameters, call the url_param() method. Use it in the same way as param(). The main difference is that it allows you to read the parameters, but not set them.
Under no circumstances will the contents of the URL query string interfere with similarly-named CGI parameters in POSTed forms. If you try to mix a URL query string with a form submitted with the GET method, the results will not be what you expect.

# references
http://cpansearch.perl.org/src/LDS/CGI.pm-3.25/cgi_docs.html#import
http://www.runoob.com/perl/perl-cgi-programming.html
