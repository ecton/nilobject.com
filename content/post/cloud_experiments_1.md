+++
title = "Experiments in the Cloud, Part 1: Traditional vs Cloud Architectures"
categories = ["aws","devops"]
date = "2015-11-26T11:50:00-08:00"
+++

I've been spending a lot of time re-evaluating my thinking of "cloud computing." Today "cloud" is so diluted of a term, I hesitate to use it. Spinning up VPSes on the fly is a form of cloud computing, but I'm talking about some of the origins of it -- [Amazon Web Services](https://aws.amazon.com/) for example. What's the difference? A lot actually.

I'm still learning as I go along, and this series of posts is meant to solve a couple of problems:

1. Writing out my thoughts and trying to explain things will help me organize my own thoughts as I try to design the future infrastructure of my current business and potential future endeavors.
2. I have a list of topics I've been wanting to blog about, but while I loved the simplicity of [postach.io](http://postach.io), I ended up hating the writing experience and formatting experience of writing in Evernote. Through this series, I'm aiming to have a fully automated blogging system which I'll describe in the next installment.

## Designing for Failure vs Hoping for Reliability

In my current setup we're architected for reliability, but anticipating failure and having reasonable recovery procedures. This is the method that most traditional setups use -- beefy hardware, load balancers in place, hardware redundancy, etc. However, try as you might, becoming "highly available" is a very tough challenge. Let's walk through a traditional setup. We'll do this by analyzing the steps to take a single database server and single webserver to improve reliability and redundancy. There are three distinct categories of failures that can take this simple architecture offline:

1. Data center failure. There are higher tier datacenters that have extreme guarantees of network and power availability, but if you're organically growing you're probably in a less expensive one. This means your data center is still very reliable, but regardless of the quality of the datacenter, you can still occasionally have issues with network and power failures.
2. Webserver failure. If the machine kernel panics or a piece of hardware fails, your website will go down if you only have one webserver.
3. Database failure. Same reasons as Webserver failure.

### Webserver redundancy and load balancing

The first step in improving reliability is to add a second webserver. The reasoning behind this is that you tend to take extra care and precaution with your database server, and also heavily restrict its access. Webservers on the other hand, developers often will be deploying regularly to, helping keep them maintained, perhaps installing the occasional package, etc. Beyond that, this is the cheapest step to improving reliability.

Once you've added a second webserver, you need to add some way to divert traffic if one goes down. Traditionally this means introducing a load balancer as well, but you could use the same methods that you would for the database server failover we'll be talking about shortly. However, long-term this will not be the approach you'll want to use, as to scale up you're going to want to have more than one webserver operating at any given time. So, what we're going to do is insert three total servers, designing for the fact that we'll need it eventually to improve our reliability.

The first as mentioned before is the second webserver. You  may need to move things like static resources to some shared filesystem, or more preferably use a CDN for your static content. The other two servers are load balancers. You could use hardware load balancers, or you can use regular servers running software like HAProxy. You'll want to use some sort of failover such as [IP failover with a heartbeat](https://www.howtoforge.com/high-availability-load-balancer-haproxy-heartbeat-debian-etch) to make sure one load balancer is always responding.  The load balancers can check the server's health and only direct traffic to it if it's online, and even better -- if it's not, it can show a nice error page rather than connection failures or timeouts.

At the end of this phase we're still susceptible to data center failures and database server failures, but we've made a big leap forward on reliability.

### Database redundancy

This phase I can't go into too much detail because it varies on exact setups based on what database type you're using. The general idea, unless you go with a true cluster setup, is to have one server in a master setup and one in a slave replication setup. Using the same type of heartbeat setup as with the load balancers, you will set up a software check that will demote the master to the slave, and promote the slave to the master. The webservers may or may not need to have some configuration to make sure they're talking to the correct server.

At the end of this, you'll end up with multiple beefy database servers that can auto-failover if the other is damaged. This step is very painful to set up, but now you're in theory as reliable as your datacenter is.

### Data center redundancy

This is where things get really challenging. While datacenters provide redundant backbones and redundant power and power generators, there are too many variables to ever truly have 100% uptime. What if you need to go beyond that? Let's take a moment here to recognize that if you're in a good datacenter, this amount of reliability will be good for almost every business. However, some businesses even 5 minutes can be more costly than the overhead of setting up data center redundancy.

The ability to fail over from one datacenter to another can be done at the DNS level with a low time-to-live (TTL). This is the only practical way to do this unless you want to purchase your own IP address space (/24 or larger) or work closely with a major backbone provider. In either event, you enter the dark art of BGP. By owning your own IP address space you can define BGP routes that allow you to publish the same IP address from both datacenters, and if one becomes unreachable BGP will drive traffic to the other. This is known as [anycasting](https://en.wikipedia.org/wiki/Anycast).

The biggest challenge is identifying datacenters that can provide low enough latency and high enough reliability so that your database servers can also replicate properly. Additionally, you want to try to minimize what overlaps of disasters could affect them. For example, a datacenter that has separate connections to the internet but is only 2 miles from the original datacenter could both be wiped out by a hurricane or tornado.

Unfortunately while I can give some ideas of how this is done, it will largely be up to your datacenter, your particular app requirements, and what is available.

## Designing for Failure

I'm going to be speaking in this section with the perspective of AWS because I think it epitomizes this concept. There are other services that do very similar abstractions, but in my research AWS truly embraces the concept of designing for failure. Let's walk back through these same failure points and evaluate it in the eyes of AWS.

### Data center redundancy

Because I've achieved every other level of redundancy through a lot of sweat and tears except data center level redundancy (we have some, but not where I'd like it to be), this was something I was really wanting to understand how "the cloud" solved. AWS embraces this right away with its concepts of [regions and availability zones (AZs)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html). A short summary is that AWS breaks its infrastructure into regions that are in different areas of the world -- east coast US, west coast US, Europe, Australia, etc. Each region is then broken down into several availability zones. Each AZ is guaranteed to have completely independent infrastructure from every other availability zone in the region. Amazon also takes care to ensure that each AZ is reasonably separate from what natural disasters could occur. They tried to ensure that only extremely catastrophic events such as a big meteor strike could wipe out more than one AZ at a time.

As we'll cover in the next sections, this design of regions and AZs is the fundamental building block of designing for failure on all levels. The key for designing for failure on AWS is to either pick services that take care of multi-AZ replication/failover for you, or to utilize the multi-AZ infrastructure to ensure you build it in yourself.

### Database redundancy

As we'll cover in the next section, you can build up VMs that mimic physical hardware, but Amazon goes a step further. If you use one of the popular databases like MySQL, PostgreSQL, etc., you can take advantage of [Amazon RDS](https://aws.amazon.com/rds/?nc2=h_l3_db). With RDS you lose some control of the basic configuration of the database server, but in exchange you can tick a checkbox telling it to take care of multi-AZ redundancy for you. It will allow you to update to the latest supported software or upgrade to a larger EC2 instance size through a rolling failover automatically. It will take care of recovering from an AZ failure automatically. In short, it removes a HUGE amount of setup that a small team could struggle staying on top of. The only cost over regular EC2 is that you lose some customization of the database server itself.

### Webserver Redundancy and Load balancing

AWS offers "Elastic Load Balancer" which can balance traffic between webservers. If your current HAProxy is mostly dumb ("if this host, do this") then you can take advantage of this service at a lower cost than running EC2 instances and mimicking your regular setup. Even if you need extra logic, you can use ELB in front of HAProxy to simplify your overall setup and only require one HAProxy instance per AZ -- since AZs are guaranteed to be relatively low latency, the single HAProxy could handle the processing while the other recovers, and even can route to both AZs with low overhead.

Unfortunately, the hardest part is the webservers themselves. Remember me saying how AWS embraces designing for failure? This is where it first becomes truly visible. Unlike virtual machines from Linode or DigitalOcean or countless other providers, EC2 virtual machines have ephemeral storage. This means if the virtual machine is powered off, you lose your local disk and it's restored from the disk image (AMI) that it was originally initialized with.

If you're like me you'd be shaking your head and asking, "Why the hell are you doing something so silly as that, Amazon?" The answer is that this structure, while painful, enforces YOU to embrace designing for failure. Machines fail. Disks fail. Datacenters fail. By designing your machines so that any persistent data is stored on a reliable medium, not on the host machine itself, it allows your machine to recover more quickly. Let's look at a couple common scenarios:

1. Host has massive storage failure. I'm confident both Amazon and traditional providers use RAIDed storage on their hosts However even if they don't, this point is still valid because RAID isn't a backup. If your RAID can tolerate 2 drives failing, you are still susceptible to the unlikely odds that three drives will fail before two replacement drives are fully rebuilt onto. In the traditional environment, your machine is hosed. You have to reinstall on a new host.

    In the Amazon world, your machine would come up on another host restored from the image specified. By designing for failure, you can minimize your downtime significantly -- storing persistent information on EBS for example.

2. Host has patches to apply that require a host machine reboot. Fairly recently Linode had to do a massive set of patches across all their hosts. This meant for the large amount of VMs we have, we received maintenance windows that our machines would be shut down and then rebooted after the host had been fully patched. This was painful. In theory Linode could have offered us to pick our own window and manually move our machine from one host to another that was already patched, but that copy would be "slow" because we'd be moving entire disks across their LAN.

    In the Amazon world, you would be notified that there is a scheduled maintenance window in which your machine would be shut down and rebooted on another host. Additionally, from what I've read they also offer the ability for you to trigger it on your own. Rather than taking minutes to copy a massive disk across the network, the speed is super fast because your machine begins booting from the AMI on the new host right away.

So, there are very valid reasons to embrace this approach. Does it annoy me? Absolutely. Running one-off VMs for utilities is a huge pain, because you can't just assume your local disk will be around after a reboot. However, EBS does make it not extremely complicated, but it's still not as easy as firing up a VM on Linode or DigitalOcean. The thing to remember is that your data isn't safe on those hosts either -- you still need to make sure you're doing backups for recovery if you do lose data.

Now, a point in Linode and DigitalOcean's favor is that I haven't lost any data with them. So, while I religiously back up and encourage everyone to do the same, I haven't had to do a recovery of any of my VMs.

## An end to part 1

AWS has an insane number of products, but above I covered some of the basics for building a webapp. Part 2 is where I will dive in a bit about what I'm now using for this blog, the vision I have, and where I'm at in the process.
