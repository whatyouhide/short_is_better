require_relative '../main'

set :output, 'cron.log'

every 1.day, at: '00:00am' do
  runner 'ShortIsBetter::IpControl.flush!'
end
