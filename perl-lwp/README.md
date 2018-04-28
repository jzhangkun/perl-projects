# Perl LWP::UserAgent
LPW::UserAgent is a very common used Perl module that assists us to send http request. When it comes to https, there comes with some tricky problems. Especially, when we needs speical SSL/TLS version to support, we need be much careful to use it. For instance: from PCI(Payment Card Industry)'s perspective, it is advised to transit from SSL and TLS 1.0 to newest TLS versin.

## Simple API
LWP::UserAgent comes with an option to support SSL - ssl_opts. 
```pl
  use LWP::UserAgent;

  $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 1 });
  $res = $ua->get("https://www.example.com");
```

It also provides SSL_ca_file and SSL_ca_path to let us coustimize file containing Certificate Authority certificates as trusted CA, otherwise, it will go and look into module Mozilla::CA, which contains Mozilla's bundle of Certificate Authority certificates.
```pl
  use LWP::UserAgent;

  $ua = LWP::UserAgent->new();
  $ua->ssl_opts(
      verify_hostname => 1,
      SSL_ca_file => 'your-ca-file-directory',
  );
  $res = $ua->get("https://www.example.com");
```

## What if
* what if we want to specify the exact ssl version?
* what if we want keys and certs in client to be verified by servers?

I'm going to summarize some ways to achieve that. I will start with introduction of LWP::Protocol::http and LWP::Protocol:https to figure out the relationship with other depencencies of modules.

## Module Relationships

![Minion](https://github.com/jzhangkun/lwp-https/blob/master/img/lwp.jpg)

To deal with https, LWP::UserAgent utilizes the protocol through LWP::UserAgent::Protocol::https. However, LWP::UserAgent::Protocol::https modules inherts most implentmentation from LWP::UserAgent::Protocol::http except for the socket instance. As we're doing https, the socket must be created with https protocol and there're couple of SSL modules that provide the way: IO::Socket::SSL, Net::SSL(from Crypt::SSLeay). To choose which one to use, you can specify the class name in environment variable PERL_NET_HTTPS_SSL_SOCKET_CLASS.

I don't have the pros and cons between IO::Socket::SSL and Net::SSL. I'm familar with the first one, so I'll cover with it mostly. 

LWP::UserAgent::Protocol::https implement its own private method "_extra_sock_opts" by overriding LWP::UserAgent::Protocol::http. And this method will return with extra options and will be passed when the new socket is created with IO::Socket::SSL, which means, you can fill SSL optinons, which are provided by IO::Socket::SSL, in this private method. Time to take a look at code of how to implement your own https modules for LWP::UserAgent to utilize:

https://github.com/jzhangkun/lwp-https/blob/master/MY_HTTPS.pm

