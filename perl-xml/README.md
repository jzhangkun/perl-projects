# perl-xml
To figure out the suitable Perl modules for XML usage.

## History of Perl and XML
forwarded from perl cookbook

Initially, Perl had only one way to parse XML: regular expressions. This was
prone to error and often failed to deal with well-formed XML (e.g., CDATA
sections). The first real XML parser in Perl was XML::Parser, Larry Wall's Perl
interface to James Clark's expat C library. Most other languages (notably
Python and PHP) also had an expat wrapper as their first correct XML parser.

XML::Parser was a prototype—the mechanism for passing components of XML
documents to Perl was experimental and intended to evolve over the years. But
because XML::Parser was the only XML parser for Perl, people quickly wrote
applications using it, and it became impossible for the interface to evolve.
Because XML::Parser has a proprietary API, you shouldn't use it directly.

XML::Parser is an event-based parser. You register callbacks for events like
"start of an element," "text," and "end of an element." As XML::Parser parses
an XML file, it calls the callbacks to tell your code what it's found.
Event-based parsing is quite common in the XML world, but XML::Parser has its
own events and doesn't use the standard Simple API for XML (SAX) events. This
is why we recommend you don't use XML::Parser directly.

The XML::SAX modules provide a SAX wrapper around XML::Parser and several other
XML parsers. XML::Parser parses the document, but you write code to work with
XML::SAX, and XML::SAX translates between XML::Parser events and SAX events.
XML::SAX also includes a pure Perl parser, so a program for XML::SAX works on
any Perl system, even those that can't compile XS modules. XML::SAX supports
the full level 2 SAX API (where the backend parser supports features such as
namespaces).

The other common way to parse XML is to build a tree data structure: element
A is a child of element B in the tree if element B is inside element A in the
XML document. There is a standard API for working with such a tree data
structure: the Document Object Model (DOM). The XML::LibXML module uses the
GNOME project's libxml2 library to quickly and efficiently build a DOM tree. It
is fast, and it supports XPath and validation. The XML::DOM module was an
attempt to build a DOM tree using XML::Parser as the backend, but most
programmers prefer the speed of XML::LibXML. In Recipe 22.2 we show
XML::LibXML, not XML::DOM.

So, in short: for events, use XML::SAX with XML::Parser or XML::LibXML behind
it; for DOM trees, use XML::LibXML; for validation, use XML::LibXML.

## XML::LibXML
/bin/libxml.pl

## XML::XPath
/bin/xpath.pl

