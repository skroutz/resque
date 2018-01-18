require 'test_helper'
require 'resque/failure/redis'
require 'resque/failure/extra'
require 'resque/failure/multiple'

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

context "Resque::Failure::Multiple" do
  setup do
    exception      = StandardError.exception("This is a test")
    worker         = Resque::Worker.new(:test)
    queue          = "queue"
    payload        = { "class" => Object, "args" => 3 }

    Resque::Failure::Redis.clear #clear redis backends from any previously saved failures

    Resque::Failure::Multiple.configure do |config|
      config.classes = [Resque::Failure::ExceptionRaiser,Resque::Failure::Redis]
    end

    @multi = Resque::Failure::Multiple.new(exception, worker, queue, payload)
  end

  test 'catches exceptions during backend.save and re-raises after all backends have tried to save' do
    assert_raise StandardError do
      @multi.save
    end
    assert_equal 1, Resque::Failure::Redis.count # Backends registered other than ExceptionRaiser should have saved the failure correctly.
  end
end
