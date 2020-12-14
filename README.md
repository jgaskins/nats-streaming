# NATS::Streaming

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     nats-streaming:
       github: jgaskins/nats-streaming
   ```

2. Run `shards install`

## Usage

Start by requiring the `nats-streaming` shard:

```crystal
require "nats-streaming"
```

To connect to a NATS Streaming (a.k.a. STAN) server, you need to supply 2 mandatory arguments and one of 3 optional arguments to the `NATS::Streaming::Client` constructor:

- `cluster_id : String`: The name of the NATS Streaming cluster to talk to
- `client_id : String`: How this client will be identified by the NATS Streaming server
- At most one of the following ways to connect to a NATS server:
  - `uri : URI`: a `nats://` or `tls://` URI that points to the NATS server your NATS Streaming server talks to
  - `servers : Array(URI)`: a list of NATS servers representing a NATS cluster
  - `nats : NATS::Client`: wrapping an existing NATS client

If you pass in an existing NATS client, closing the `NATS::Streaming::Client` will not close the `NATS::Client` because it does not own it. If you pass in a `URI` or `Array(URI)`, the client will start up its own `NATS::Client`, which _will_ be closed when the streaming client closes.

If you don't pass in any of them, it will connect by default to a NATS server on `localhost:4222`. This makes it dead simple to get started developing locally.

```crystal
require "nats-streaming"

stan = NATS::Streaming::Client.new(
  cluster_id: "test-cluster",
  client_id: "pub-sub-test-#{UUID.random}",
)

# Subscribe to the given subject, executing the block when a message is received.
# Options additional options are:
#   subject : String
#   queue_group : String? = nil                 # Define the queue group to use here. Messages will only be delivered once to a queue group.
#   max_in_flight : Int32 = 10                  # Limit the number of messages this subject receives before we can acknowledge
#   ack_wait = 10.seconds                       # How long to wait before re-delivering
#   durable_name : String? = nil                # Create a durable subscription that survives NATS server restarts
#   start_position : Nats::StartPosition? = nil # Where the first subscription for this queue group will begin in the stream
#     - :new_only
#     - :last_received
#     - :time_delta_start
#     - :sequence_start
#     - :first
#   start_sequence : UInt64? = nil              # When specifying `start_position: :sequence_start`, start at this offset
#   start_time_delta : Int64? = nil             # When specifying `start_position: :time_delta_start`, start this many nanoseconds after the first message in the stream
stan.subscribe "foo", queue_group: "bar" do |msg|
  pp msg
end

# Publish, wait for acknowledgement
stan.publish "foo", "lol"

# Nonblocking publish, the acknowledgement will be yielded to the block later.
stan.publish "foo", "lol" do |response|
  pp response
end

sleep 1.second
stan.close # Close the connection cleanly so the server knows we bailed and won't try to send us more messages
```

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/jgaskins/nats-streaming/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Jamie Gaskins](https://github.com/jgaskins) - creator and maintainer
