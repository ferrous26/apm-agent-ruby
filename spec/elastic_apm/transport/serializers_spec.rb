# frozen_string_literal: true

module ElasticAPM
  module Transport
    RSpec.describe Serializers do
      subject { described_class.new(Config.new) }

      it 'initializes with config' do
        expect(subject).to be_a Serializers::Container
      end

      describe '#serialize' do
        pending
      end
    end
  end
end
