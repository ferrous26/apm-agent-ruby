# frozen_string_literal: true

require 'elastic_apm/transport/connection'
require 'elastic_apm/transport/worker'

module ElasticAPM
  module Transport
    # @api private
    class Base
      include Logging

      def initialize(config)
        @config = config
        @queue = SizedQueue.new(config.api_buffer_size)
        @pool = Concurrent::FixedThreadPool.new(config.pool_size)
        @workers = {}
      end

      attr_reader :config, :queue, :workers

      def start
        boot_workers
      end

      def stop
        stop_workers
      end

      def submit(resource)
        queue.push(resource, true)
      rescue ThreadError
        error 'Queue is full (%i items), skipping…', config.api_buffer_size
        nil
      end

      private

      def boot_workers
        @workers = (0...config.pool_size).each_with_object({}) do |i, workers|
          worker = Worker.new(config, queue)
          workers[i] = worker

          @pool.post do
            worker.work_forever
            @workers.delete(i)
          end
        end
      end

      def stop_workers
        return unless @pool.running?

        debug 'Stopping workers'
        @workers.values.each { queue << Worker::StopMessage.new }
        @pool.shutdown
        debug 'Shutting down pool'

        return if @pool.wait_for_termination(5)

        warn "Worker pool didn't close in 5 secs, killing ..."
        @pool.kill
      end
    end
  end
end
