Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = ENV["CI"].present?
  config.consider_all_requests_local = true
  config.action_dispatch.show_exceptions = :rescuable
  config.public_file_server.headers = { "cache-control" => "public, max-age=3600" }
end
