require "../src/nats-streaming"

nats = NATS::Streaming::Client.new(
  cluster_id: "test-cluster",
  client_id: "pub-sub-test-#{UUID.random}",
  uri: URI.parse("nats:///"),
)

puts "Publishing..."
count = 0i64
total = 0i64
start = Time.monotonic
loop do
  nats.publish "foo", "bar"
  total += 1i64
  count += 1i64

  if count >= 100_000i64
    pp outgoing_msg_per_sec: (count // (Time.monotonic - start).total_seconds).format
    Fiber.yield
    count = 0i64
    start = Time.monotonic
  end
rescue ex
  pp ex
  pp total: total
  break
end


puts "Press enter to stop"
gets
