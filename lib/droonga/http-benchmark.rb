# -*- coding: utf-8 -*-

class HttpBenchmark
  attr_reader :duration, :threads_count

  MIN_DURATION = 1.0
  MAX_THREADS_COUNT = 16

  def initialize(params)
    @duration = [params[:duration], MIN_DURATION].max
    @threads_count = [params[:threads_count], MAX_THREADS_COUNT].min
  end

  def run
    raise "not implemented"
  end
end
