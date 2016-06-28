require 'webmock/rspec'
require 'byebug'

WebMock.disable_net_connect!

RSpec.configure do |config|

  config.expect_with :rspec do |expectations|
     expectations.syntax = [:expect, :should]
  end

  config.mock_with :mocha

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.order = :random
  Kernel.srand config.seed

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    $pusher.stubs(:trigger)
    DatabaseCleaner.cleaning do
      example.run
    end
  end

end
