+++
date  = "2014-07-01T12:00:00-05:00"
title = "PostgreSQL: Dealing with half a billion rows"
tags   = ["postgresql", "databases", "optimization"]
topics = ["postgresql", "databases", "optimization"]
slug   = "postgresql-dealing-with-half-a-billion-rows"
+++

As the primary DBA at the company, I knew of a problem I wasn’t quite sure how to solve brewing. The short summary is that ever since the very first applications, we have been tracking statistics of app usage. Since we’ve been building apps for over 5 years now, it’s quite a massive data set.

### Infancy

When I first started, I wanted to run as little software on the server as possible. This was back when the webserver and the database server were the same physical box without any performance-increasing RAID setups. I opted to store statistic information in sqlite with one database per show. This made a lot of sense at the time to me, but I was also very naive in how everything would look after several years.

The first issue I ran into was during the first truly major event we had an app for – 2010 International CES. With tens of thousands of users refreshing their apps and submitting their statistics, the syncs were piling up due to how sqlite does locks during writes. I quickly patched it by having the sync APIs write to a temporary atomic store (accomplished using a list as a queue in [redis](http://redis.io/), which I already had running for other caching reasons).

This process worked well for the single-server setup, but I knew in the back of my mind it would become a pain someday. I wasn’t quite sure of my scaling strategy yet – would I go horizontal by using more inexpensive hardware, or would I go for more power and get a centralized set of database servers?

### Childhood

SQLite is a wonderful wonderful technology. However, it’s really not meant to be used as a backend for multiple threads let alone multiple servers. Our next investment in hardware was to split the database server from the webserver, and have a honest-to-goodness RAID. However, the difference of having sqlite accessed remotely was going to be too much to handle, and what if I added a second webserver someday?

I made the choice to migrate all of the SQLite databases to PostgreSQL. I decided to go away from the one-database-per-customer approach for statistics by evaluating these pros and cons:

Pros:

* Ability to query and compare multiple shows at once
* Simpler design
* Known quantity

Cons:

* Scaling horizontally would be potentially more challenging
* Optimizing one large table could be difficult (Oh boy if I realized the depth of what this con was…)
* Such was born the device statistics table. Refactoring the code wasn’t difficult, and because of my abstraction of using * Redis to temporarily store the queue of incoming stats, it was easy to cut over – just temporarily disable the process that cleared that queue, deploy the code, copy all the existing info in, then re-enable the process now that it’s pointing to psql.

### Adolescence

As the device stats table grew, I tweaked our indexes and thought that was enough. However, any seasoned DBA knows that indexes are only half the battle. From my previous experience I knew the best next-step solution was to begin relying less on raw queries across the indexed table and instead create an aggregation process.

For those who haven’t dealt with a large dataset like this before, what I mean by an aggregation process is to simply convert raw “hit” type information into pre-calculated “count” rows. Instead of doing a `count(\*\)` you would end up with a `sum(count)`, and the aggregate table has fewer rows which makes lookups and scans much faster.

Aggregation has its downsides: the process can be time consuming in and of itself, and if not fast enough, you’re faced with viewing stats that are outdated frequently. While the statistics for our apps are far from life or death, there’s both utility and a sense of “fun” that arise from seeing stats that are almost real time.

### The Teenage Years

The aggregation process worked well, and still worked moderately well as our data set kept getting larger. However, even a year ago, I noticed several problems that are commonplace with psql.

The simple aggregation process I wrote used deletes and inserts to ensure rows weren’t being counted twice. Inserts and deletes don’t reuse the same space on disk, and thus the indexes and tables became fragmented. Reindexing isn’t a fun process either, as issuing a true reindex acquires locks on the database that prevent inserting new records. This essentially freezes the aggregation process. However, the benefit of defragmented indexes is significant enough that even a lock is worth it, or what I tended to do more frequently is create a set of new indexes with the same parameters and then drop the old ones. This avoided the locking problem, but took longer and required more disk space.

The next approach I took was partitioning the tables. Since aggregation to some extent can be “locked in” after a certain point, I began splitting old data off by timestamp. So, 2009 data was in its own table, 2010 in its own, 2011 etc. For 2012 I started splitting by quarter, and then by month for 2013 and 2014.

This approach worked well, but eventually the gains just weren’t enough.

### The College Years

I started experimenting with several concepts, all which had merits but their own hangups as well.

#### Per-app Database

I didn’t actually experiment with this much, and that’s because after some very quick search results I discovered that many people reported issues with auto-vacuuming and the fact that psql dedicates sets of files for each database. The issue is that with thousands of databases you’ll run into max open file limits very easily. The hassle of that I didn’t want to deal with, but in those same search results I found my next concept I started experimenting with.

#### Per-app Schema

Schemas are honestly a little weird in psql. I say this not because they aren’t a useful construct, but rather that “setting the current schema” is a concept that is done in a different way.

For example:

default schema public table some_global_table schema app1 table device_stats schema app2 table device_stats

By default, you can reference tables in the “public” schema without qualification, ie `SELECT * from some_global_table`, and you can reference tables in other schemas by using the schema name, ie `SELECT * from app1.device_stats`. The mechanism to change the “current” schema is by setting the search path like this: `SET search_path = 'app1'`. You can specify a full search path, which is cool, but this did just seem a little “weird” to me.

However, I began seeing a way to maintain most of the code in the same manner but start splitting every app into its own schema. Sure enough, splitting sped things up by the virtue of reducing the data set sizes.

Unfortunately after splitting all of the data on another server for testing, I realized that having thousands of schemas just felt really ugly. It solved the problems, but not in a way I was happy with.

### Amazon’s Redshift

[Redshift](http://aws.amazon.com/redshift/) is a custom-built software solution that solves big-data problems by enforcing physical sorting of the tables and offering a sort of map-reduce functionality from within standard sql. It’s a really cool technology, and I was able to get our raw stats table loaded up and queries ran pretty quickly. I played around with a lot of configurations, and decided this is where I wanted to move my stats to.

Over the course of the next couple weeks, we were making other drastic changes to aggregation which made the turnaround much faster but also was more optimized for a Redshift type setup.

However, those couple weeks led me to really ponder the setup. I had been focused on speeding up aggregation, and rethinking aggregation entirely meant I could focus on trying to speed up the main stats table. Could I salvage our current setup?

### CLUSTER

Perhaps one of the worst choices maintainers of technology can make is to choose terms that make google results hard to pin down. Such is the case of the [CLUSTER statement](http://aws.amazon.com/redshift/). Postgres calls individual instances running on a server a “cluster”, so when I initially saw references to clusters, my brain processed the search results as, “Oh, I definitely don’t want to set up a cluster for every single app.”

However, something finally jumped out at me in one of my searches last week. The summary of that link is that CLUSTERing a table physically reorders the table based on the order of the index that’s specified. This is precisely how Redshift operates, but not using the same commands. But would this change be enough to combat the gains of custom designed software like Redshift?

Hardware-wise, I was comparing an Amazon Dense Compute cluster:

2 virtual CPUs
7 Elastic Compute Units
15 GB of RAM
160GB of SSD RAID
Against our current standard database node:

2 quad core CPUs
Dedicated to running only our databases
48-64 GB of RAM
1.6 TB of 15K SAS RAID
I was convinced we should be able to beat Redshift, but being the amateur DBA who already spent more time on this problem than I originally wanted to, I was fine going to Redshift if I couldn’t beat it quickly. Redshift didn’t have to be permanent, I could always migrate back off of it in the future once I possessed more wisdom.

And thus a plan was born.

### Adulthood

This past weekend I began by disabling aggregation and preparing to migrate to Redshift if needed. I turned off that Resque queue flusher, and began my CLUSTER experiment. I first had to create a new index on the half billion rows we had, and since I was doing a complex index across 5 columns, it took a very long time.

Learning step 1: I was using the default `maintenance_work_mem` and not as big of `work_mem` as I should have. The initial index took 16 hours to create, but it was CPU bound not disk bound. My hypothesis post-hoc is that because I wasn’t allowing postgres to read in as much data and operate on it in memory it was paging in and out which thankfully hit disk page caches but still requires psql to do too small of data sets while operating.

I set those settings a bit higher and started the cluster operation. Unfortunately psql has no progress bars or ways to query progress, so I was watching using iotop in accumulative mode to gauge roughly how much longer I had to wait.

After a painfully long wait (around 28 hours total), the operation succeeded. This took longer because it had to physically reorder the entire database on disk, and then regenerate the index since all of the data moved from underneath it.

The first step after CLUSTER is to ANALYZE. I kicked that process off, and then tested the updated aggregation script against the table. The larger queries that could take up to 4 minutes before returned in about 1500ms. And, compared to Redshift, it won by about 800ms on average.

I finished deploying and testing the new code, and everything has been extremely smooth sailing. Our worker queues that used to always have a backlog of aggregation processes actually clear up completely before starting on the next round of aggregations.

### Life’s Lessons

The moral of this story boils down to something software developers know already: when something smells, don’t wait until it breaks to fix it. Start looking for a solution before the stench is overwhelming. I waited a bit longer than I should have on this one, and to carry the same olfactory analogy, by the time I paid attention to the stench, I was smelling it from down the hall of where the problem mainly stemmed from.

By stepping back and rethinking the problem, I was able to cut through to the root of the issues and ultimately discover the (currently) optimal solution for our setup. The reality is that I knew that while a half billion records is a large number, it’s not nearly a “huge” data set. It’s a large data set, but I know DBAs all over the world face data sets this large on a daily basis. It was that knowledge that drove me to figure out how to optimize my psql install rather than abandon it.
