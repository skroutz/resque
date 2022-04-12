module Resque
  module WorkerJobRemoval
    def self.prepended(base)
      base.extend SmartIdExtractor
    end

    module SmartIdExtractor
      attr_accessor :smart_id_extractor
    end

    def startup
      super
      start_kill_operations_thread if fork_per_job?
    end

    def perform_with_fork(job, &block)
      @last_fork_time = Time.now.to_i
      super
    end

    def work_one_job(job = nil, &block)
      return false if paused?
      return false unless job ||= reserve

      if (name = suspend?(job))
        Job.create("suspended:#{name}", job.payload['class'], *job.payload['args'])
        return true
      end

      super(job, &block)
    end

    def queues
      super.reject { |queue| queue.start_with?('suspended:') }
    end

    def extract_smart_id(job_payload)
      if !(km = self.class.smart_id_extractor).nil?
        km.call(job_payload)
      else
        nil
      end
    end

    def job_matches_op?(job_class, job_smart_id, class_of_op, smart_id_of_op)
      if job_smart_id && smart_id_of_op
        job_class == class_of_op && job_smart_id == smart_id_of_op
      else
        job_class == class_of_op
      end
    end

    # Check the suspend operations placed using Resque.start_suspending for matching
    # with the given job. If there is a match, return the operation's name.
    def suspend?(job)
      return false unless job.payload.is_a?(Hash) && job.payload['class']

      suspend_ops = data_store.smembers('suspend_ops')
      return false if suspend_ops.empty?

      jobs_to_suspend = suspend_ops.map do |so|
        so.split('/')
      end

      job_class = job.payload['class']
      job_smart_id = extract_smart_id(job.payload)

      matching_op = jobs_to_suspend.find do |(_name, class_to_suspend, smart_id_to_suspend)|
        job_matches_op?(job_class, job_smart_id, class_to_suspend, smart_id_to_suspend)
      end

      return false unless matching_op
      matching_op.first
    end

    # Check every 5 seconds the kill operations placed by Resque.killall and kill
    # the current running child if the job matches the given class or class + smart id.
    def start_kill_operations_thread
      @kill_operations_thread = Thread.new do
        loop do
          sleep 5

          child = defined?(@child) ? @child : nil
          j = job

          next unless child
          next unless j['payload'].is_a?(Hash) && j['payload']['class']

          candidate_kill_ops = data_store.smembers('kill_ops').select do |k|
            k.split('/').first.to_i > @last_fork_time
          end

          next if candidate_kill_ops.empty?

          jobs_to_kill = candidate_kill_ops.map { |cko| cko.split('/')[1..2] }

          curr_job_class = j['payload']['class']
          curr_job_smart_id = extract_smart_id(j['payload'])

          should_kill_child = jobs_to_kill.any? do |jtk|
            class_to_kill, smart_id_to_kill = jtk

            job_matches_op?(curr_job_class, curr_job_smart_id, class_to_kill, smart_id_to_kill)
          end

          begin
            Process.kill('KILL', child) if should_kill_child
          rescue Errno::ESRCH # No such process
            next
          end
        end
      end
    end
  end
end
