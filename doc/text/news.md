# News

## 1.0.2: 2014-07-30

 * 'drnbench-request-response'
   * Report aborted requests as slow requests.
   * Report response status and index for slow requests.
   * Add ability to specify default timeout via the `--default-timeout` option.
   * Add ability to specify interval between each benchamrk via the `--interval` option.
 * New utility command `drnbench-extract-searchterms` to extract values of a specific column from a result of Groonga's select command.
 * New utility command `drnbench-generate-select-patterns` to generate patterns file for benchmark of Groonga's select command via HTTP.

## 1.0.1: 2014-07-29

 * `drnbench-request-response`
   * Report throughput more correctly.
   * Report percentages of returned HTTP statuses correctly.
   * Report max elapsed time correctly.
   * Add ability to report slow requests via the `--n-slow-requests` option.
   * Accept pattern group specific parameters.

## 1.0.0: 2014-01-29

The first release!!!
