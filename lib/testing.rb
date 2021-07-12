#!/usr/bin/env ruby
require 'gitlab'

Gitlab.configure do |config|
  config.endpoint = 'http://gitlab/api/v3'
end
puts("++++++++++++++++++++++++++ GITLAB PREPARATION RB SCRIPT +++++++++++++++++++++++\n")
user = Gitlab.session('admin@example.com','cosmobotsDeployPassGIT')
puts(user.to_json)

require "./config/environment"

puts(User.all)
User.all.each{|u|
puts(u)
}
puts("fin")
