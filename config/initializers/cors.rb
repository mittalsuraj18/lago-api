# frozen_string_literal: true

# NOTE: Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before(0, Rack::Cors) do
  allow do
    if ENV.key?('LAGO_FRONT_URL')
      uri = URI(ENV['LAGO_FRONT_URL'])
      additional_cors = ENV['ADDITIONAL_CORS']

      frontend_origin = if uri.port.in?([80, 443])
                          uri.host
                        else
                          [uri.host, uri.port].join(':')
                        end
      if additional_cors
        all_additional_cors = additional_cors.split(",")
        origins frontend_origin, *all_additional_cors
      else
        origins frontend_origin
      end
    elsif Rails.env.development?
      origins 'app.lago.dev', 'api'
    end

    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head]
  end
end
