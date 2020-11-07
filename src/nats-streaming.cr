require "socket"
require "uuid"
require "nats"

require "./protobufs/protocol.pb"

module Protobuf
  module Message
    def to_slice : Bytes
      io = IO::Memory.new
      to_protobuf io
      io.to_slice
    end
  end

  struct Buffer
    def self.new(slice : Bytes)
      new IO::Memory.new(slice)
    end
  end
end

# TODO: Write documentation for `Nats::Streaming`
module NATS::Streaming
  VERSION = "0.1.0"

  alias Data = String | Bytes

  class Error < ::Exception
  end

  class Client
    @cluster_id : String
    @client_id : String
    @nats : NATS::Client
    @close_requests : String
    @ping_interval : Time::Span
    @ping_max_out : Int32
    @publish_prefix : String
    @subscribe_requests : String
    @unsubscribe_requests : String
    @subscribe_close_requests : String
    @connection_id : Bytes

    def initialize(@cluster_id : String, @client_id : String, @uri = URI.parse("nats:///"))
      @nats = NATS::Client.new(@uri)
      @heartbeat_inbox = "heartbeats.#{@cluster_id}.#{@client_id}"
      @nats.subscribe @heartbeat_inbox do |msg|
        if subject = msg.reply_to
          @nats.publish subject, ""
        end
      end
      @connection_id = UUID.random.to_s.to_slice

      reply = @nats.request "_STAN.discover.#{@cluster_id}",
        message: Nats::ConnectRequest.new(
          client_id: @client_id,
          heartbeat_inbox: @heartbeat_inbox,
          protocol: 1,
          conn_id: @connection_id,
          ping_interval: 5,
          ping_max_out: 6,
        ).to_slice,
        timeout: 2.seconds

      if reply
        response = Nats::ConnectResponse.from_protobuf(IO::Memory.new(reply.body))
        if error = response.error
          raise Error.new(error)
        end

        @close_requests = response.close_requests.not_nil!
        @ping_interval = response.ping_interval.not_nil!.seconds
        @ping_max_out = response.ping_max_out.not_nil!
        @publish_prefix = response.pub_prefix.not_nil!
        @subscribe_requests = response.sub_requests.not_nil!
        @unsubscribe_requests = response.unsub_requests.not_nil!
        @subscribe_close_requests = response.sub_close_requests.not_nil!
      else
        raise Error.new("Could not make a connection to #{cluster_id.inspect}")
      end
    end

    def publish(subject : String, message : Data)
      pub_message = Nats::PubMsg.new(
        client_id: @client_id,
        guid: Random::Secure.hex,
        subject: subject,
        data: message.to_slice,
        conn_id: @connection_id,
      )
      reply = @nats.request "#{@publish_prefix}.#{subject}", pub_message.to_slice, timeout: 2.seconds
      if reply
        response = Nats::PubAck.from_protobuf(IO::Memory.new(reply.body))
        if error = response.error
          raise Error.new(error)
        end
      else
        raise Error.new("Could not publish message on subject #{subject.inspect}")
      end
    end

    def publish(subject : String, message : Data, &block : Nats::PubAck ->) : Nil
      pub_message = Nats::PubMsg.new(
        client_id: @client_id,
        guid: Random::Secure.hex,
        subject: subject,
        data: message.to_slice,
        conn_id: @connection_id,
      )
      @nats.request "#{@publish_prefix}.#{subject}", pub_message.to_slice, timeout: 2.seconds do |reply|
        response = Nats::PubAck.from_protobuf(IO::Memory.new(reply.body))
        if error = response.error
          raise Error.new(error)
        else
          block.call response
        end
      end
    end

    def subscribe(
      subject : String,
      queue_group : String? = nil,
      max_in_flight : Int32 = 10,
      ack_wait = 10.seconds,
      durable_name = nil,
      start_position : Nats::StartPosition? = nil,
      start_sequence : UInt64? = nil,
      start_time_delta : Int64? = nil,
      &block : Message ->
    )
      a = Random::Secure.next_int
      b = Random::Secure.next_int
      inbox_id = (a.to_i64 * b.to_i64).abs.to_s(62)
      inbox = "inbox.#{@client_id}.#{inbox_id}"

      request = Nats::SubscriptionRequest.new(
        client_id: @client_id,
        subject: subject,
        q_group: queue_group,
        inbox: inbox,
        max_in_flight: max_in_flight,
        ack_wait_in_secs: ack_wait.total_seconds.to_i,
        durable_name: durable_name,
        start_position: start_position,
        start_sequence: start_sequence,
        start_time_delta: start_time_delta,
      )
      reply = @nats.request @subscribe_requests, request.to_slice, timeout: 2.seconds
      if reply
        response = Nats::SubscriptionResponse.from_protobuf(IO::Memory.new(reply.body))
        if error = response.error
          raise Error.new(error)
        elsif ack_inbox = response.ack_inbox
          subscription = @nats.subscribe inbox, queue_group do |msg|
            message = Message.from_protobuf_msg(Nats::MsgProto.from_protobuf(msg.body))
            block.call message
            ack = Nats::Ack.new(
              subject: message.subject,
              sequence: message.sequence,
            )
            @nats.publish ack_inbox.not_nil!, ack.to_slice
          end
        end
      else
        raise Error.new("Could not subscribe to #{subject}")
      end
    end

    def close
      @nats.close
    rescue ex : IO::Error
    end

    @mutex = Mutex.new
    def exclusive
      @mutex.synchronize { yield }
    end
  end

  class Subscription
    getter ack_inbox : String
    getter subscription : ::NATS::Subscription

    def initialize(@ack_inbox, @subscription)
    end
  end

  struct Message
    getter subject : String
    getter data : Bytes
    getter reply : String?
    getter timestamp : Time?
    getter sequence : UInt64
    getter? redelivered : Bool
    getter redelivery_count : UInt32

    def self.from_protobuf_msg(msg : Nats::MsgProto)
      new(
        subject: msg.subject.not_nil!,
        data: msg.data.not_nil!,
        reply: msg.reply,
        timestamp: Time::UNIX_EPOCH + msg.timestamp.not_nil!.nanoseconds,
        sequence: msg.sequence || 0_u64,
        redelivered: msg.redelivered || false,
        redelivery_count: msg.redelivery_count || 0_u32,
      )
    end

    def initialize(@subject, @data, @reply, @timestamp, @sequence, @redelivered, @redelivery_count)
    end
  end
end
