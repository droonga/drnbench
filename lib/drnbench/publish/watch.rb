require "droonga/watch_schema"

module Drnbench
  module Publish
    class Watch
      class << self
        def command
          "watch"
        end

        def subscribe(keyword)
          {
            "condition" => keyword,
            "subscriber" => "subscriber for #{keyword}",
          }
        end

        def feed(keyword)
          {
            "targets" => {
              "keyword"  => keyword,
            },
          }
        end
      end
    end
  end
end
