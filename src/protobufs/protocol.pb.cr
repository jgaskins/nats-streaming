## Generated from protocol.proto for nats
require "protobuf"

require "./gogo.pb.cr"

module Nats
  enum StartPosition
    NewOnly = 0
    LastReceived = 1
    TimeDeltaStart = 2
    SequenceStart = 3
    First = 4
  end
  
  struct PubMsg
    include ::Protobuf::Message
    
    contract_of "proto3" do
      optional :client_id, :string, 1
      optional :guid, :string, 2
      optional :subject, :string, 3
      optional :reply, :string, 4
      optional :data, :bytes, 5
      optional :conn_id, :bytes, 6
      optional :sha256, :bytes, 10
    end
  end
  
  struct PubAck
    include ::Protobuf::Message
    
    contract_of "proto3" do
      optional :guid, :string, 1
      optional :error, :string, 2
    end
  end
  
  struct MsgProto
    include ::Protobuf::Message
    
    contract_of "proto3" do
      optional :sequence, :uint64, 1
      optional :subject, :string, 2
      optional :reply, :string, 3
      optional :data, :bytes, 4
      optional :timestamp, :int64, 5
      optional :redelivered, :bool, 6
      optional :redelivery_count, :uint32, 7
      optional :crc32, :uint32, 10
    end
  end
  
  struct Ack
    include ::Protobuf::Message
    
    contract_of "proto3" do
      optional :subject, :string, 1
      optional :sequence, :uint64, 2
    end
  end
  
  struct ConnectRequest
    include ::Protobuf::Message
    
    contract_of "proto3" do
      optional :client_id, :string, 1
      optional :heartbeat_inbox, :string, 2
      optional :protocol, :int32, 3
      optional :conn_id, :bytes, 4
      optional :ping_interval, :int32, 5
      optional :ping_max_out, :int32, 6
    end
  end
  
  struct ConnectResponse
    include ::Protobuf::Message
    
    contract_of "proto3" do
      optional :pub_prefix, :string, 1
      optional :sub_requests, :string, 2
      optional :unsub_requests, :string, 3
      optional :close_requests, :string, 4
      optional :error, :string, 5
      optional :sub_close_requests, :string, 6
      optional :ping_requests, :string, 7
      optional :ping_interval, :int32, 8
      optional :ping_max_out, :int32, 9
      optional :protocol, :int32, 10
      optional :public_key, :string, 100
    end
  end
  
  struct Ping
    include ::Protobuf::Message
    
    contract_of "proto3" do
      optional :conn_id, :bytes, 1
    end
  end
  
  struct PingResponse
    include ::Protobuf::Message
    
    contract_of "proto3" do
      optional :error, :string, 1
    end
  end
  
  struct SubscriptionRequest
    include ::Protobuf::Message
    
    contract_of "proto3" do
      optional :client_id, :string, 1
      optional :subject, :string, 2
      optional :q_group, :string, 3
      optional :inbox, :string, 4
      optional :max_in_flight, :int32, 5
      optional :ack_wait_in_secs, :int32, 6
      optional :durable_name, :string, 7
      optional :start_position, StartPosition, 10
      optional :start_sequence, :uint64, 11
      optional :start_time_delta, :int64, 12
    end
  end
  
  struct SubscriptionResponse
    include ::Protobuf::Message
    
    contract_of "proto3" do
      optional :ack_inbox, :string, 2
      optional :error, :string, 3
    end
  end
  
  struct UnsubscribeRequest
    include ::Protobuf::Message
    
    contract_of "proto3" do
      optional :client_id, :string, 1
      optional :subject, :string, 2
      optional :inbox, :string, 3
      optional :durable_name, :string, 4
    end
  end
  
  struct CloseRequest
    include ::Protobuf::Message
    
    contract_of "proto3" do
      optional :client_id, :string, 1
    end
  end
  
  struct CloseResponse
    include ::Protobuf::Message
    
    contract_of "proto3" do
      optional :error, :string, 1
    end
  end
  end
