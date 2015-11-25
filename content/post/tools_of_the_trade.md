+++
title = "Tools of the Trade"
date = "2014-01-15T20:00:00-05:00"
slug = "tools-of-the-trade"
categories = ["databases","devops"]
+++

One of the posts I wrote last time I restarted this blog was a list of services or tools that I use that have aided me in running my business. Given that I wrote that a few years ago, I figured that an updated list would be in order.

One stark change that has happened with me is that while I still dive in on iOS and Android code, my primary focus these days is on architectural and forward thinking things. As a side result of scaling the business from where we started 5 years ago to today, I have a larger focus on the “dev-ops” perspective than I used to, and my daily tools are more focused on these two roles more than they ever have been.

## Infrastructure

*   [NodePing](http://nodeping.com/): At the top of my list is the monitoring service I know I had in my previous writeup. They have slightly different pricing models than before, but they are still the most affordable that I’m aware of, and they’re great people to work with. If you have many websites or services (smtp, etc) that need to be monitored, these guys should be your go-to. If you are looking for an inexpensive monitor for an http site that doesn’t check every minute, I still highly recommend [UptimeRobot](http://uptimerobot.com/) which is free for up to 50 sites and checks every 5 minutes. 

*   [NewRelic](http://newrelic.com/): I think NewRelic has an incredible product, but we’re not paying customers. On their free plan, you get 24 hour retention of some very useful logging information. However, the jump from free to Pro is drastic, and while there are some great fetaures that I sometimes want, I just can’t stomach the cost when many of the hosts I want that extra information on are VPSes that cost $20 a month. If I was to pay full price (I know they have discounts) for Pro on all the machines I would want it on, it would cost more than our hosting bill costs on its own.

    Their free tier provides some great monitoring and can help narrow down problems quickly. I highly recommend using them for their free tier at least. I just wish there was some plan that I could justify the cost for because I do love the service that much. 

*   [DigitalOcean](http://digitalocean.com/): I found out about this VPS hosting provider late last year, and I’ve only heard and experienced great things. They offer a smaller/cheaper tier than Linode but then above that tier Linode and DigitalOcean are very similar in pricing and specs. I like the fresh take that DigitalOcean has. They aren’t nearly as full featured as Linode, but I loved their SSD offerings before Linode recently switched over to SSDs for their hosting. Definintely a company to check out for your VPS hosting – not the cheapest, but pretty close with so far great service and support. 

*   [Linode](http://linode.com/): The main provider of most of my VPSes is Linode. I was feeling a little stale with them although I have always been a fan. Their [pretty major switch to SSDs](https://www.evernote.com/OutboundRedirect.action?dest=https%3A%2F%2Fblog.linode.com%2F2014%2F04%2F17%2Flinode-cloud-ssds-double-ram-much-more%2F) shows me why I should remain a fan of them. The only painful part I have is something they couldn’t really control – I’ve been a customer of theirs so long that many of my servers were created with VPSes were recommended being created with 32-bit kernels, and to take advantage of the SSD installs you need a 64-bit kernel. So I’m slowly rebuilding those servers – the ones that would benefit from SSDs.

    But overall, I want to just say these guys have spectacular support, affordable pricing, and are one of those companies I’m glad to have supported and used all of these years.

*   [Redis](http://redis.io/): Redis has been around as long as my company has. It is a very fast key-value in-memory database with a lot of great features. It has atomic operations, list data types, set operations, and more. I use it in a variety of ways ranging from a simple cache to a place to put incoming information that can be processed by background workers.

It isn’t meant to replace your relational database, although many people have used it as the only database for a project. My recommendation however is to continue using a relational database for your primary data store and using this to help solve problems that might be trickier in a relational database. 

*   [PostgreSQL](http://postgresql.org/): In the days before I was a DBA (if I can call myself that), I still had a fondness for PostgreSQL due to MySQLs history for corrupting user data. That’s not an issue these days if you use the proper table formats, and MySQL is a capable server. However, [this video demonstrates](https://www.evernote.com/OutboundRedirect.action?dest=https%3A%2F%2Fvimeo.com%2F43536445) many reasons why I vastly prefer PostgreSQL.
The summary of that video is that MySQL in some cases takes the sanctity of your data and twists it rather than giving errors. For example, performing an INSERT on a table with a “int NOT NULL” column with no value specified inserts a row with 0 in that column, rather than providing an error.

    Are there ways that MySQL is better than PostgreSQL? Undoublty. But there are also many ways that PostgreSQL is better than MySQL. Is there any one true database server? Definitely not. I just am sticking with PostgreSQL on my own projects. 

*   [SaltStack](http://www.saltstack.com/): This is one of my more recent additions to my toolkit. There are many distributed system manamagent solutions, and I’m not an expert of any. I tried my best to understand and configure one of our simpler webservers with Chef, and got lost. I couldn’t see myself getting much further with Puppet. In the process, I discovered SaltStack and gave it a whirl. I absolutely love it. It still took a bit to really understand, but within a day I had a completely automated solution to spinning up a new VPS on either Linode or DigitalOcean and getting it completely configured as a webserver for one of our products.

    Being able to execute commands or update configurations across all servers of a specific product is amazing. I love the power. I highly recommand on a project that you anticipate growing taking the time to set up something like SaltStack to help you manage multiple servers.

## Managing a Team

I manage a completely remote development team that spans 4 platforms. Keeping organized and connected is a struggle. I plan on going a bit more in-depth about the challenges of managing a remote company in a separate post, but here I can give a brief overview of some of the tools we use:

*   [HipChat](http://hipchat.com/): For several years, we used Campfire from 37 signals (now known as Basecamp). It’s a capable product, but with [their recent change](http://37signals.com/) they no longer are going to put any effort into the product. I really dislike paying for a service that the creators admitted they aren’t going to focus on anymore. I started a search that lasted several months for the next best solution, and HipChat was one of the better ones.

    HipChat on its surface is similar to Campfire in many ways, but adds some nice features. It was a little more expensive for our team size, but while our trial was going on [they announced they were going free for unlimited users](https://www.evernote.com/OutboundRedirect.action?dest=https%3A%2F%2Fblog.hipchat.com%2F2014%2F05%2F27%2Fhipchat-is-now-free-for-unlimited-users%2F). They recently added one-on-one audio and video sharing, including screen sharing. It’s a little buggy, but if you don’t use USB audio it actually works quite flawlessly. Once it’s stabilized, I’m confident we’ll be paid customers.

    However, the benefits of having persistent group chat for your team at $0 per month are just outstanding. If you don’t have a good group chat setup, definite give HipChat a try. 

*   [Skype](http://skype.com/): For voice calls, Skype just works. I don’t actually love Skype, there are a lot of things I dislike about it. But the pros of it outweigh the cons: cheap unlimited dialing out from your computer and easy high quality voice calls including conferencing multiple people. Skype fills many gaps and solves many problems that the alternatives just don’t have a good solution for. 

*   [Redmine](http://redmine.org/): We adopted Redmine within the first year of starting the company. It’s a great open-source ticket tracking/project management solution. If you are looking for a standard ticket/issue tracking system, this should be on your list to consider. 

*   [Passpack](http://passpack.com/): Securely sharing passwords is a tricky problem, and this is a pretty clever website. It’s not the easiest to use tool, but once you get the flow figured out it works stunningly. With it I have one paid account and each of my developers that needs access to private keys or passwords links via their sharing feature, and I can add them to the proper groups giving them access to view those entries. If they add a new one, they can share and transfer ownership to the main account.

## Day to Day Tools

*  [Sublime Text](http://www.sublimetext.com/): Sublime lives up to its name for me. I used to use BBEdit or TextMate. However, they both had their downsides and their benefits. I still use BBEdit for some things, but for 99% of my day-to-day workflow, I live in Sublime Text. It is a wonderful text editor that works the way I want it to, and has a lot of great customizations and add-ons available. The only downside for me is that discovering some of those settings and add-ons can be tough. If you aren’t happy with your text editor, definitely give this one a try. 

*   [Transmit](http://panic.com/transmit/): I commonly have to do file transfers to our servers or from other FTP servers. In the back of my mind I always thought that there probably was a pretty good cheaper solution than Transmit these days. For example, I knew of CyberDuck and recommended that to many of the people I worked with. However, several people in the last year have heard me say, “I used Transmit, but CyberDuck is free.” They went on to download the Transmit trial after using CyberDuck for a while and ended up buying it.

    There’s something about its simplicity and flow that just makes it a joy to use compared to other remote file clients. 

*   [LastPass](http://lastpass.com/): For my personal password management I currently use LastPass. I still use 1Password for some things, but LastPass is inexpensive and cross-platform. I don’t like it always being built into the web browser, but functionality wise and price wise I love it. 1Password is a great product, but for the longest time it had a poor integration with Chrome which is what led me to try LastPass. I haven’t really looked back since it works well enough and the cross-platform buy-in of 1Password is a little too high for me.

## What else?

I could go on, but those are the highlights of what I consider my core tools. There are many other things I use on a day to day basis, but some are either required by everyone who works on that platform (Xcode) or ones that have been beaten to death and most people have heard of. Hopefully on this list there’s a few items you haven’t heard of that might solve some problems you’re facing.
