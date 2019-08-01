require 'test_helper'
require 'minitest/mock'

require 'resque/failure/base'

class TestFailure < Resque::Failure::Base
end

class CustomException < StandardError; end

describe "Base failure class" do
  it "allows calling all without throwing" do
    with_failure_backend TestFailure do
      assert_empty Resque::Failure.all
    end
  end

  it "sets a list of blacklisted exceptions" do
    blacklisted_exceptions = [CustomException].map(&:name).map(&:to_s)
    exc = CustomException.new("Custom Exception error occured")
    queue = 'my-queue'
    worker = Resque::Worker.new([queue])
    payload = {"find" => "MyModel.find(100)"}

    t = TestFailure.new(exc, worker, queue, payload)
    t.set_blacklisted_exceptions(blacklisted_exceptions)

    assert_equal blacklisted_exceptions, t.blacklisted_exceptions
  end
end
