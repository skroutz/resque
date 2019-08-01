module Resque
  module Failure
    # All Failure classes are expected to subclass Base.
    #
    # When a job fails, a new instance of your Failure backend is created
    # and #save is called.
    class Base
      # The exception object raised by the failed job
      attr_accessor :exception

      # The worker object who detected the failure
      attr_accessor :worker

      # The string name of the queue from which the failed job was pulled
      attr_accessor :queue

      # The payload object associated with the failed job
      attr_accessor :payload

      # The exceptions that will not be pushed to failed queue
      attr_reader :blacklisted_exceptions

      def initialize(exception, worker, queue, payload)
        @exception = exception
        @worker    = worker
        @queue     = queue
        @payload   = payload
        @blacklisted_exceptions = []
      end

      # Set a list of blacklisted exceptions
      #
      # The method sets a list of exceptions which will
      # not be pushed to the failed queue when a job fails and it's
      # exception is included to the blacklisted ones.
      #
      # @param [Array<String>] exceptions the list of exceptions to blacklist
      def set_blacklisted_exceptions(exceptions)
        @blacklisted_exceptions = exceptions
      end

      # When a job fails, a new instance of your Failure backend is created
      # and #save is called.
      #
      # This is where you POST or PUT or whatever to your Failure service.
      def save
      end

      # The number of failures.
      def self.count(queue = nil, class_name = nil)
        0
      end

      # Returns an array of all available failure queues
      def self.queues
        []
      end

      # Returns a paginated array of failure objects.
      def self.all(offset = 0, limit = 1, queue = nil)
        []
      end

      # Iterate across failed objects
      def self.each(*args)
      end

      # A URL where someone can go to view failures.
      def self.url
      end

      # Clear all failure objects
      def self.clear(*args)
      end

      def self.requeue(*args)
      end

      def self.remove(*args)
      end

      # Logging!
      def log(message)
        @worker.log(message)
      end
    end
  end
end
