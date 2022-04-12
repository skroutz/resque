require 'test_helper'

KILLALL_TESTFILE = '/tmp/resque_kill_thread_test'

describe 'Resque::WorkerJobRemoval' do
  class SlowJob
    def self.perform
      $slow_job_started = true
      sleep 10
      File.write(KILLALL_TESTFILE, 'touch')
    end
  end

  before do
    $slow_job_started = false
    @worker = Resque::Worker.new('*')
    @worker.start_kill_operations_thread
  end

  after do
    File.delete(KILLALL_TESTFILE) rescue nil
  end

  it 'is able to kill only the jobs of a given Class' do
    File.delete('/tmp/resque_kill_thread_test') rescue nil


    Resque::Job.create(:jobs, GoodJob)
    Resque::Job.create(:jobs, SlowJob)

    assert_equal 2, Resque.size(:jobs)

    Thread.new do
      sleep 1
      Resque.killall('SlowJob')
    end

    assert_equal true, @worker.work_one_job
    assert_equal true, @worker.work_one_job

    assert_equal false, File.exists?(KILLALL_TESTFILE)
    assert_equal 0, Resque.size(:jobs)
  end

  it 'is able to kill only the jobs of a given Class + Smart Id' do
    File.delete('/tmp/resque_kill_thread_test') rescue nil

    Resque::Job.create(:jobs, GoodJob)
    Resque::Job.create(:jobs, SlowJob, 'arg1')
    Resque::Worker.smart_id_extractor = ->(job_payload) do
      job_payload['args'].first
    end

    assert_equal 2, Resque.size(:jobs)

    Thread.new do
      while $slow_job_started == false
        sleep 0.1
      end

      Resque.killall('SlowJob', 'arg1')
    end

    assert_equal true, @worker.work_one_job
    assert_equal true, @worker.work_one_job

    assert_equal false, File.exists?(KILLALL_TESTFILE)
    assert_equal 0, Resque.size(:jobs)

    Resque::Worker.smart_id_extractor = nil
  end

  it 'is able to suspend only the jobs of a given Class' do
    Resque::Job.create(:jobs, GoodJob)
    Resque::Job.create(:jobs, BadJob)

    assert_equal 2, Resque.size(:jobs)

    Resque.start_suspending('test', 'BadJob')

    assert_equal true, @worker.work_one_job
    assert_equal true, @worker.work_one_job

    assert_equal 1, Resque.size('suspended:test')
    assert_equal 0, Resque.size(:jobs)
  end

  it 'is able to suspend only the jobs of a given Class + Smart Id' do
    Resque::Job.create(:jobs, GoodJob)
    Resque::Job.create(:jobs, BadJob, 'arg1')
    Resque::Worker.smart_id_extractor = ->(job_payload) do
      job_payload['args'].first
    end

    assert_equal 2, Resque.size(:jobs)

    Resque.start_suspending('test', 'BadJob', 'arg1')

    assert_equal true, @worker.work_one_job
    assert_equal true, @worker.work_one_job

    assert_equal 1, Resque.size('suspended:test')
    assert_equal 0, Resque.size(:jobs)

    Resque::Worker.smart_id_extractor = nil
  end

  it 'does not reserve jobs from queues starting with `suspended:`' do
    Resque::Job.create(:jobs, GoodJob)
    Resque::Job.create('suspended:test', BadJob)

    assert_equal true, @worker.work_one_job
    assert_equal false, @worker.work_one_job

    assert_equal 1, Resque.size('suspended:test')
    assert_equal 0, Resque.size(:jobs)
  end
end
