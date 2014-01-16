# Drnbench

## Description

Drnbench is a benchmark tool for Droonga.

It may be used for other HTTP servers (in future versions).


## How to run benchmark?

### Benchmarking of request-responsne style commands, with a Droonga Engine instance

Drnbench can benchmark performance of a Droonga Engine with random requests.

In this scenario, you have to prepare patterns of requests for commands.
Drnbench will start multiple clients and send many requests based on the patterns file, via fluentd protocol (msgpack).

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
 3. Run drnbench with the pattern file.
    
        # cd ~/drnbench
        # RUBYLIB=lib/ bin/drnbench \
            --start-n-clients=1 \
            --end-n-clients=32 \
            --step=1 \
            --duration=10 \
            --wait=0.01 \
            --mode=http-droonga
            --request-patterns-file=/tmp/patterns.json \
            --host=localhost \
            --port=23003
    
 4. You'll get a result like:
    
        n_clients,total_n_requests,queries_per_second,min_elapsed_time,max_elapsed_time,average_elapsed_time,200
        1,33,3.3,0.164632187,0.164632187,0.19133309036363635,0
        2,70,7.0,0.161510877,0.161510877,0.1846983412285715,0
        3,87,8.7,0.1658357,0.1658357,0.24303329366666668,0
        ...


### Benchmarking of the "search" command, with a combination of a Droonga Protocol Adapter and a Droonga Engine.

(Note: this feature is not implemented yet.)

 1. Create a pattern file.
 2. Setup a Droonga Engine server. For example, localhost:23003.
 3. Setup a Protocol Adapter server. For example, localhost:3003.
 4. Run drnbench with the pattern file and an extra option `--type=rest`.
    
        # cd ~/drnbench
        # RUBYLIB=lib/ bin/drnbench \
            --type=rest \
            --start-n-clients=1 \
            --end-n-clients=32 \
            --step=1 \
            --duration=10 \
            --wait=0.01 \
            --request-patterns-file=/tmp/patterns.json \
            --host=localhost \
            --port=3003
    
 4. You'll get a result.


## License

The MIT License (MIT)

Copyright (c) 2013 Droonga Project

See LICENSE.txt for details.
