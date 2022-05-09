module Resque
  module JobRemoval
    SUSPEND_OPS_KEY = 'suspend_ops'.freeze
    KILL_OPS_KEY = 'kill_ops'.freeze

    # Instruct all workers to kill their current running job
    # if it matches the given class or class + smart id.
    #
    # The smart id can be a string which will be used by a custom
    # smart id matcher to identify & kill a subset of the class's jobs.
    def killall(klass, smart_id = nil)
      data_store.multi do |multi|
        multi.sadd(KILL_OPS_KEY, [Time.now.to_i, klass, smart_id].compact.join('/'))
        multi.expire(KILL_OPS_KEY, 60)
      end
    end

    # Instruct all workers to start suspending the jobs
    # if they match the given class or class + smart id.
    #
    # The smart id can be a string which will be used by a custom
    # smart id matcher to identify & suspend a subset of the class's jobs.
    def start_suspending(name, klass, smart_id = nil)
      data_store.sadd(SUSPEND_OPS_KEY, [name, klass, smart_id].compact.join('/'))
    end

    # Instruct all workers to stop suspending the jobs
    # of the given operation name.
    def stop_suspending(name)
      so = data_store.smembers(SUSPEND_OPS_KEY).find { |so| so.split('/').first == name }
      raise "Cannot find suspend operation '#{name}'" if so.nil?

      data_store.srem(SUSPEND_OPS_KEY, so)
    end

    # Get a list of the active suspend operations by their name
    def suspend_operations
      data_store.smembers(SUSPEND_OPS_KEY)
    end

    # Requeue the suspended jobs by their name
    def requeue_suspended(name, dst_queue)
      src_queue = "suspended:#{name}"

      while (job = pop(src_queue))
        Job.create(dst_queue, job['class'], *job['args'])
      end
    end
  end
end
