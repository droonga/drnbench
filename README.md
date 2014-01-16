# Drnbench

## Description

Drnbench is a benchmark tool for Droonga.

It may be used for other HTTP servers.

Drnbench provides features to send multiple random requests with different settings periodically.
Number of clients (requests) in each period will be automatically increased gradually.
So you'll be able to guess the limit performance of the throughput of a server, via the report like following:

    n_clients,total_n_requests,queries_per_second,min_elapsed_time,max_elapsed_time,average_elapsed_time,200
    1,33,3.3,0.164632187,0.164632187,0.19133309036363635,0
    2,70,7.0,0.161510877,0.161510877,0.1846983412285715,0
    3,87,8.7,0.1658357,0.1658357,0.24303329366666668,0
    ...


## How to run benchmark?

### Benchmarking with an HTTP server

Drnbench can benchmark throughput performance of an HTTP server with random requests.

In this scenario, you have to setup an HTTP server and prepare patterns of requests.
Drnbench will start multiple clients and send many requests based on the patterns file.

 1. Create a patterns file in the format:
    
        {
          "(pattern type 1 name)": {
            "frequency": (appearance ratio in all requests),
            "path":      "(path to the endpoint)",
            "method":    "(HTTP method)",
            "patterns":  [
              { "body": (request body 1 sent by POST method) },
              { "body": (request body 2 sent by POST method) },
              ...
            ]
          }
          "(patterns type 2 name)": {
            "frequency": (appearance ratio in all requests),
            "patterns":  [
              {
                "path":   "(path to the endpoint 1)",
                "method": "(HTTP method)",
                "body":   (request body 1 sent by POST method)
              },
              {
                "path":   "(path to the endpoint 2)",
                "method": "(HTTP method)",
                "body":   (request body 2 sent by POST method)
              },
              ...
            ]
          },
          ...
        }
    
    For example, a file "patterns.json" like:
    
        {
          "user search": {
            "frequency": 0.61,
            "method":    "GET",
            "patterns":  [
              { "path": "/users?q=foo" },
              { "path": "/users?q=bar" },
              ...
            ]
          },
          "item search": {
            "frequency": 0.32,
            "method":    "GET",
            "patterns":  [
              { "path": "/items?q=foo" },
              { "path": "/items?q=bar" },
              ...
            ]
          },
          ...
        }
    
 2. Setup an HTTP server. For example, localhost:80.
 3. Run drnbench with the pattern file.
    
        # cd ~/drnbench
        # RUBYLIB=lib/ bin/drnbench- \
            --start-n-clients=1 \
            --end-n-clients=32 \
            --step=1 \
            --duration=10 \
            --wait=0.01 \
            --mode=http \
            --request-patterns-file=/tmp/patterns.json \
            --host=localhost \
            --port=80
    
 4. You'll get a report.


### Benchmarking of request-responsne style commands, with a Droonga-based search system

Drnbench can benchmark throughput performance of a Droonga-based search system with random requests.

In this scenario, you have to setup a Droonga-based search system and prepare patterns of requests for commands.
Drnbench will start multiple clients and send many requests based on the patterns file.

 1. Create a patterns file in the format:
    
        {
          "(pattern type 1 name)": {
            "frequency": (appearance ratio in all requests),
            "command":   "(command name)",
            "patterns":  [
              { command parameters 1 },
              { command parameters 2 },
              { command parameters 3 },
              ...
            ]
          }
          "(patterns type 2 name)": {
            ...
          },
          ...
        }
    
    For example, a file "patterns.json" like:
    
        {
          "user search": {
            "frequency": 0.61,
            "command":   "search",
            "patterns":  [
              {
                "queries": {
                  "users": {
                    "source":    "User",
                    "condition": "age >= 10",
                    "sortBy":    { "keys": ["-birthday"], "offset": 0, "limit": 100" },
                    "output":    {
                      "elements": [
                        "count",
                        "records"
                      ],
                      "attributes": ["_key", "name", "age", "birhtday"],
                      "offset": 0,
                      "limit":  100
                    }
                  }
                }
              },
              ...
            ]
          },
          "item search": {
            "frequency": 0.32,
            "command":   "search",
            "patterns":  [
              {
                "queries": {
                  "users": {
                    "source":    "Item",
                    "condition": "visible == true",
                    "sortBy":    { "keys": ["title"], "offset": 0, "limit": 100" },
                    "output":    {
                      "elements": [
                        "count",
                        "records"
                      ],
                      "attributes": ["title", "price"],
                      "offset": 0,
                      "limit":  100
                    }
                  }
                }
              },
              ...
            ]
          },
          ...
        }
    
 2. Setup a Droonga Engine server. For example, localhost:23003.
 3. Setup a Protocol Adapter server. For example, localhost:3003.
 4. Run drnbench with the pattern file.
    
        # cd ~/drnbench
        # RUBYLIB=lib/ bin/drnbench \
            --start-n-clients=1 \
            --end-n-clients=32 \
            --step=1 \
            --duration=10 \
            --wait=0.01 \
            --mode=http-droonga \
            --request-patterns-file=/tmp/patterns.json \
            --host=localhost \
            --port=3003
    
 5. You'll get a report.


## License

The MIT License (MIT)

Copyright (c) 2013-2014 Droonga Project

See LICENSE.txt for details.
