# Alex Shukhman's GORPC project

_Some messing around with making a dynamic RPC server. Probably not a good idea._

## Tech Stack

* Golang (1.17)
* Protobuf (3)
* HTTP

## Background

> I'm learning golang, protobufs, and RPC standard here, so bear with me please!

The intention of this is to help me learn more about alternatives to the stack that I'm comfortable with in baby steps. At this point in my career I've worked primarily with RESTful (ish) API's written in Node and Python, but I recognize that neither language is exactly great for scenarios where being closer to the silicone is a must. For that reason, I decided to try to make a server that can build its own services in Golang, a language I've been exposed to, but haven't had much experience with.

_Yes, I know that this is basically like any CLI made by the big boy cloud services companies, I'm just learning something new..._

## Proposal

Since this is just a personal project, I'm not all too worried about cybersecurity (and good thing too, this would be a nightmare for cyber security). I'm going to keep it all deployable to a cloud-native containerized environment with access to a cloud-native data store (still working out if that will be a bucket storage, RDBS, noSQL document store or a Redis cluster but that depends on how this planning phase goes). As an added challenge I will impose the following rules:

1. This will be written entirely on the `main` branch of the git repo (we're phasing out `master` because who needs it...)
2. At least one commit a week, regardless of how small it is.
3. This will NOT work over GRPC (keeping it home-grown HTTP native RPC stuff)
4. No outside contributers (I can look up docs and even tutorials, but no copying and pasting code and nobody but I can contribute until it's a semi-completed POC)

## Architecture

_Because this is the first time I'm doing something like this, I'm going to keep track of all my failed ideas as well so feel free to laugh along as I stumble through this._

### Goal

* Management server
  * Should be traditional RESTful API
    * *Reasoning*: This would never make sense and an RPC API. I thought about it, but the system is too complex. I'll stick to REST over HTTP and leave the RPC stuff for the middleware and the client using it.
  * Accept requests for **creating new RPC definitions**
    * Create new RPC definitions in datastore based on request
    * Deduping is not necessary
    * This will not make the RPC definition available as endpoint until requested
  * Accept requests for **editing extant RPC definitions**
    * Create new RPC definitions in datastore based on request (versioned from previous)
    * This will not make the new RPC definition available as an endpoint until requested
    * This should prevent duplications of the same versions by denying the request if the version is the same
  * Accept list request to **list RPC definitions available**
    * This should also list alternate versions
    * All versions should have their own identifier
    * This should be human- and machine-readable
  * Accept status request to **list all running and available RPC endpoint on demo service bus**
    * This probably doesn't need to be super complicated, basically just list all the ones that should be running, we could use a service like StatusCake to manage uptime if this were a real deal system.
  * Accept run request to **deploy and start new RPC endpoint on demo service bus**
  * Accept kill request to **stop and destroy RPC endpoint**
  * Maybe in the future allow manifests or something to bulk-update, but we're getting ahead of ourselves.
* RPC demo service bus
  * Should be an HTTP-based RPC service bus
  * Should be **editable programmatically**
  * **Each service endpoint should be separate** from the others. We don't need to share memory, calling sibling procedures can be done via RPC
  * Might want to create in a managed, auto-scaling environment (suggest: Lambda or GCF or Firebase)
* Cloud architecture management middleware
  * Should **deploy accepted RPC definitions**
    * This will require some HTTP-based requests to the cloud service provider. Those should be modularized for easy replacement.
  * Should **discover deployed RPC definitions**
    * This is for the list of the running services
  * Should be effectively **the stop gap between the RESTful management server and the RPC demo service bus**

### Version 08.29.21

* Theory
  * Focusing on the following concepts:
    * Domain-Driven Design (DDD)
    * Command-Query Separation (CQS)
    * Scalable Microservice Architecture
* Management Server
  * GoLang HTTP server built with basic RESTful design
  * HTTP controller
    * Responsible for accepting/rejecting requests
    * Breaks down request into Service Bus (SB) components
    * Should pass SB components to queue
      * Example queue entities (note, these might be overboard)
        * *Hitting non-existant endpoint*
          * Enqueue "render 404" SB component
        * *Hitting authorized endpoint*
          * Enqueue "authorization" SB component
          * Enqueue "handle endpoint with authorization" SB component
        * *Handling endpoint component*
          * Enqueue "validate requirements for endpoint" SB component
          * Enqueue "determine subcomponents* SB component
  * Queue Management Layer
    * Handles individual domain-specific queues asynchonously
      * Each individual entity in the queue knows its parent thread
      * Each individual entity in the queue knows its domain
      * Each entity in the queue should be capable of being handled asynchronously from all other elements of the queue
  * Service Bus
    * Orchestration layer, this will call the other layers and eventually the most basic components
    * TODO
