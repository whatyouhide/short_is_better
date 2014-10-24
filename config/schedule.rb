require_relative '../main'

set :output, 'logs/cron.log'

every 1.day do
  runner 'ShortIsBetter::IpControl.reset!'
end
