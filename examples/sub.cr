require "../src/nats-streaming"
require "./latency_check"
require "set"

nats = NATS::Streaming::Client.new(
  cluster_id: "test-cluster",
  client_id: "subscribe-test-#{UUID.random.to_s}",
  uri: URI.parse("nats:///"),
)

latencies = [] of Time::Span
nats.subscribe "latency.check", start_position: :first, queue_group: ARGV.first do |msg|
  latencies << Time.utc - LatencyCheck.from_json(IO::Memory.new(msg.data)).sent_at
end

spawn do
  last_checked_at = Time.monotonic
  loop do
    sleep 1
    now = Time.monotonic
    if latencies.any?
      sorted = latencies.sort
      average = latencies.sum / latencies.size if latencies.any?
      p50 = sorted[(latencies.size * 0.5).to_i]?
      p90 = sorted[(latencies.size * 0.9).to_i]?
      p99 = sorted[(latencies.size * 0.99).to_i]?
      max = sorted[-1]?
      pp throughput: latencies.size // (now - last_checked_at).total_seconds, avg: average, p50: p50, p90: p90, p99: p99, max: max
      latencies.clear
      last_checked_at = Time.monotonic
    end
  end
end

puts Process.pid
puts "Press enter to stop"
gets

nats.close
