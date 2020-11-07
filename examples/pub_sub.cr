require "../src/nats-streaming"

nats = NATS::Streaming::Client.new(
  cluster_id: "test-cluster",
  client_id: "pub-sub-test-#{UUID.random}",
  uri: URI.parse("nats:///"),
)

nats.subscribe "omg" do |msg|
  pp msg
end

nats.publish "omg", "bar" do |response|
  pp response
end

puts "Press enter to stop"
gets
