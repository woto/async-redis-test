class TestController < ApplicationController
  def index
    require 'async'
    require 'async/redis'

    endpoint = Async::Redis.local_endpoint
    client = Async::Redis::Client.new(endpoint, connection_limit: 3)

    Async do |task|
      condition = Async::Condition.new

      publisher = task.async do
        condition.wait

        listeners_count = client.publish 'status.frontend', 'good'
        Rails.logger.info("Total listeners: #{listeners_count}")
      end

      subscriber = task.async do
        client.subscribe 'status.frontend' do |context|
          condition.signal # We are waiting for messages.

          type, name, message = context.listen

          pp type, name, message
        end
      end
    ensure
      client.close
    end
    head(204)
  end
end
