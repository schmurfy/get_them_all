= What is it ?

Get Them All is my personal try at building a versatile and powerful web downloader, its goal is pretty simple:
download all the targets and keep up to date with new content by remembering what was downloaded.

It should be able to download ay file type and try as much as possible to not make any assumptions on how the
targeted website is built.

EventMachine is used to power the core, hpricot is used to parse the html.

# Why ?

I simply never found any tool fulfilling my needs so I made mine ;)


# What can it do for you

First let's start by what is currently supported:

- authentication (partially by hand)
- the referer is passed from one page to another so any leecher detection
  by referer will fail
- cookies are passed too
- parallel download, you decide how many parallel tasks are executed
  you can go as high as you want but don't be stupid !
- multiple storage backend, currently the files can be saved in:
  - local disk
  - dropbox
- javascript parsing with therubyracer, yes you read that well,
  if you are crawling a javascript powered site and need to read javascript
  you can use this to extract the informations you need.

Any website is considered as a reversed pyramid, let's take a gallery website as an example:

- the first level would be the page containing all the thumbnails
- the second level would be a page showing the picture (each link collected in level 0
  will lead to a different page on level 2)
- the third level would be the link to the picture itself

I decided on this model after some testing and until now I never found a
website where this cannot be applied (a website with fiels to download)


# Current state

The application is already ready for my needs and may be for someone else.
Currently all the connections errors may not be correctly handled especially if
the web server really has trouble keeping connections alive to serve the clients
(like for the example above).


# Usage

Look at the examples folder, there is two way of using this gem:

As an application, try running:

```bash
./bin/gta exec examples/wallpaper -s data
```

Or as a library, try this:

```bash
ruby examples/standalone.rb
```



# Disclaimer

As with most open source projects you are responsible for your actions, if you start
a crawler with a lot of parallel tasks and manage to get banned for your favorite
wallpaper site I have nothing to do with this ok ?  
Don't be stupid and everything will be fine, for my needs I rarely need more than 
2 examiners and 1/2 downloaders.

