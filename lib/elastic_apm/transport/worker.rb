# frozen_string_literal: true

require 'elastic_apm/transport/serializers'
require 'elastic_apm/transport/filters'

module ElasticAPM
  module Transport
    # @api private
    class Worker
      include Logging

      # @api private
      class StopMessage; end

      # @api private
      class FlushMessage; end

      def initialize(config, queue, conn_adapter: Connection)
        @config = config
        @queue = queue

        @stopping = false

        @connection = conn_adapter.new(config)
        @serializers = Serializers.new(config)
        @filters = Filters.new(config)
      end

      attr_reader :queue, :filters, :name, :connection, :serializers

      def stop
        @stopping = true
      end

      def stopping?
        @stopping
      end

      # rubocop:disable Metrics/MethodLength
      def work_forever
        while (msg = queue.pop)
          case msg
          when StopMessage
            stop
          else
            process msg
          end

          next unless stopping?

          debug 'Stopping worker -- %s', self
          @connection.flush
          break
        end
      end
      # rubocop:enable Metrics/MethodLength

      private

      def process(resource)
        serialized = serializers.serialize(resource)
        @filters.apply!(serialized)
        @connection.write(serialized.to_json)
      end
    end
  end
end
