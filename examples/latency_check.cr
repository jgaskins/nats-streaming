require "json"

module FloatTime
  def self.from_json(json : JSON::PullParser)
    Time::UNIX_EPOCH + json.read_float.seconds
  end

  def self.to_json(time : Time, json : JSON::Builder)
    json.number time.to_unix_f
  end
end

struct LatencyCheck
  include JSON::Serializable

  @[JSON::Field(converter: FloatTime)]
  getter sent_at : Time = Time.utc

  def initialize(@sent_at = Time.utc)
  end
end
