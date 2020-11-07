require "../src/nats-streaming"
require "./latency_check"

nats = NATS::Streaming::Client.new(
  cluster_id: "test-cluster",
  client_id: "pub-sub-test-#{UUID.random}",
  uri: URI.parse("nats:///"),
)

spawn do
  8.times do
    spawn do
      200_000.times do
        # sleep 100.milliseconds
        nats.publish "latency.check", LatencyCheck.new.to_json
      end
    end
  end
end

puts Process.pid
puts "Press enter to stop"
gets

nats.close
