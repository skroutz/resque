require 'test_helper'
require 'resque/failure/multiple'
require 'resque/failure/redis'
require 'resque/failure/extra'

module Resque
  module Failure
    # A failure backend that only raises errors on save
    class ExceptionRaiser < Base
      extend Resque::Failure::Extra

      def save
        raise StandardError.exception("Bazinga on save")
      end
    end
  end
end

describe "Resque::Failure::Multiple" do

  it 'requeue_all and does not raise an exception' do
    with_failure_backend(Resque::Failure::Multiple) do
      Resque::Failure::Multiple.classes = [Resque::Failure::Redis]
      exception = StandardError.exception('some error')
      worker = Resque::Worker.new(:test)
      payload = { "class" => Object, "args" => 3 }
      Resque::Failure.create({:exception => exception, :worker => worker, :queue => "queue", :payload => payload})
      Resque::Failure::Multiple.requeue_all # should not raise an error
    end
  end

  describe "backend retry logic" do
    before do
      # clear redis backends from any previously saved failures
      Resque::Failure::Redis.clear

      Resque::Failure::Multiple.configure do |config|
        config.classes = [Resque::Failure::ExceptionRaiser, Resque::Failure::Redis]
      end
    end

    after do
      Resque::Failure::Multiple.configure do |config|
        config.classes = [Resque::Failure::Redis]
      end
    end

    it 'catches exceptions during backend.save and re-raises after all backends have tried to save' do
      exception = StandardError.exception("This is a test")
      worker = Resque::Worker.new(:test)
      queue = "queue"
      payload = { "class" => Object, "args" => 3 }

      @multi = Resque::Failure::Multiple.new(exception, worker, queue, payload)
      assert_raises StandardError do
        @multi.save
      end

      # Backends registered other than ExceptionRaiser should have saved the
      # failure correctly.
      assert_equal 1, Resque::Failure::Redis.count
    end
  end
end
