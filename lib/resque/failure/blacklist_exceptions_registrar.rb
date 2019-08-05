module Resque
  module Failure
    # A module to access blacklisted exceptions
    # on a class level
    module BlacklistExceptionsRegistrar
      def self.included(base)
        base.extend ClassMethods
      end

      # Class methods for accessing
      # blacklisted exceptions
      module ClassMethods
        # Set a list of blacklisted exceptions
        #
        # The method sets a list of exceptions which will
        # not be pushed to the failed queue when a job fails and it's
        # exception is included to the blacklisted ones.
        #
        # @param [Array<String>] exceptions the list of exceptions to blacklist
        # @raise [StandardError] if the exceptions argument is not an array
        # @return [void]
        def set_blacklisted_exceptions(exceptions)
          unless exceptions.is_a?(Array)
            raise StandardError.new("The exceptions argument must be an array")
          end

          @blacklist = exceptions
        end

        # Fetch the blacklisted exceptions of a failure backend class
        #
        # @return [Array<String>]
        def get_blacklisted_exceptions
          return @blacklist if defined?(@blacklist)

          []
        end
      end

      # Check if the raised exception belongs
      # to the backend's blacklisted exceptions.
      #
      # @return [true, false] true if raised exception is blacklisted,
      #   false otherwise
      def blacklisted_exception_raised?
        self.class&.get_blacklisted_exceptions&.include?(@exception.class.to_s)
      end
    end
  end
end
