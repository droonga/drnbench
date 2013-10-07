# -*- coding: utf-8 -*-

class HttpBenchmark
  attr_reader :duration, :threads_count

  MIN_DURATION = 1.0
  MAX_N_THREADS = 16

  def initialize(params)
    @duration = [params[:duration], MIN_DURATION].max
    @n_threads = [params[:n_threads], MAX_N_THREADS].min
  end

  def run
    raise "not implemented"
  end
end
