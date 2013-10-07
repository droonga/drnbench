# -*- coding: utf-8 -*-

class HttpBenchmark
  attr_reader :duration, :threads_count

  MIN_DURATION = 1.0
  MAX_N_THREADS = 16

  TOTAL_N_REQUESTS = 1000,

  def initialize(params)
    @duration = [params[:duration], MIN_DURATION].max
    @n_threads = [params[:n_threads], MAX_N_THREADS].min
    @n_requests = params[:n_requests] || TOTAL_N_REQUESTS

    if params[:request_pattern]
      params[:request_pattern][:frequency] = 1
      @request_patterns = [params[:request_pattern]]
    else
      @request_patterns = params[:request_patterns]
    end
    populate_requests
  end

  def run
    raise "not implemented"
  end

  private
  def populate_requests
    @requests = []
    @current_request = 0

    @request_patterns.each do |request_pattern|
      populate_request_pattern(request_pattern)
    end

    @requests.shuffle!
  end

  def populate_request_pattern(request_pattern)
    frequency = request_pattern[:frequency].to_f
    n_requests = @n_requests * frequency

    base_patterns = nil
    if request_pattern[:pattern]
      base_patterns = [request_pattern[:pattern]]
    end
      base_patterns = request_pattern[:patterns]
    else
    base_patterns = base_patterns.shuffle

    0.upto(n_requests) do |count|
      @requests << base_patterns[count % base_patterns.size]
    end
  end
end
