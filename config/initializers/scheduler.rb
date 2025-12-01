# Periodic scraping & maintenance scheduler
# Controlled via environment variables:
#  ENABLE_SCHEDULER=0     -> disables all scheduling
#  ACTIVE_COLLECT_INTERVAL -> default: 5m   (collect_active)
#  FEED_COLLECT_INTERVAL   -> default: 30m  (collect_feeds)
#  CLEAN_INTERVAL          -> default: 6h   (clean_old_data)
#  GRAPH_INTERVAL          -> default: 1h   (save_graph)
#
# Runs only in server processes (not console, rake, or test).

return unless ENV['ENABLE_SCHEDULER'].present?
return if defined?(Rails::Console)
return if File.split($0).last == 'rake'
return if Rails.env.test?

require 'rufus-scheduler'
require 'rake'

Rails.application.load_tasks unless Rake::Task.tasks.any?

Rails.application.config.after_initialize do
  scheduler = Rufus::Scheduler.singleton

  collect_interval = ENV.fetch('COLLECT_INTERVAL', '5m')
  clean_interval  = ENV.fetch('CLEAN_INTERVAL', '6h')
  graph_interval  = ENV.fetch('GRAPH_INTERVAL', '1h')

  def invoke_reenable(task_name)
    Rake::Task[task_name].reenable
    Rake::Task[task_name].invoke
  rescue => e
    Rails.logger.error("Scheduler task #{task_name} failed: #{e.message}")
  end

  scheduler.every collect_interval, overlap: false do
    invoke_reenable('collect_active')
  end

  scheduler.every collect_interval, overlap: false do
    invoke_reenable('collect_feeds')
  end

  scheduler.every clean_interval, overlap: false do
    invoke_reenable('clean_old_data')
  end

  scheduler.every graph_interval, overlap: false do
    invoke_reenable('save_graph')
  end

  Rails.logger.info "Rufus::Scheduler started with intervals: active=#{collect_interval}, clean=#{clean_interval}, graph=#{graph_interval}"
end
