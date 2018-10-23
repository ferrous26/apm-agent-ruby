# frozen_string_literal: true

require 'spec_helper'

module ElasticAPM
  module Transport
    RSpec.describe Base do
      let(:config) { Config.new }

      subject { described_class.new config }

      describe '#initialize' do
        its(:queue) { should be_a Queue }
      end

      describe '#start' do
        let(:config) { Config.new(pool_size: 2) }

        it 'boots workers' do
          subject.start
          expect(subject.workers.length).to be 2
        end
      end

      describe '#stop' do
        let(:config) { Config.new(pool_size: 2) }

        it 'stops all workers' do
          subject.start
          subject.stop
          expect(subject.workers.length).to be 0
        end
      end

      describe '#submit' do
        it 'adds stuff to the queue' do
          subject.submit Transaction.new
          expect(subject.queue.length).to be 1
        end

        context 'when queue is full' do
          let(:config) { Config.new(api_buffer_size: 5) }

          it 'skips if queue is full' do
            5.times { subject.submit Transaction.new }

            expect(config.logger).to receive(:error)

            expect { subject.submit Transaction.new }
              .to_not raise_error

            expect(subject.queue.length).to be 5
          end
        end
      end
    end
  end
end
