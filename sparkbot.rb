#!/usr/bin/env ruby
require "socket"
require "openssl"
require "net/http"
require 'json'

# Variables
@help_msg     = ""
@server       = "irc.cat.pdx.edu"
@port         = "6697"
@nick         = "spark"
@channel      = "#robots"
@channelPass  = "catsonly"
@graphitePass = "catsonly"

# Connect
@socket = TCPSocket.open(@server, @port)
@ssl_context = OpenSSL::SSL::SSLContext.new()
@irc_server = OpenSSL::SSL::SSLSocket.new(@socket, @ssl_context)
@irc_server.connect

@irc_server.puts "USER Spark 0 Spark :I iz a bot"
@irc_server.puts "NICK #{@nick}"
@irc_server.puts "JOIN #{@channel} #{@channelPass}"

def get_that_graphite_data (whatData)
  url = "https://arbiter.cat.pdx.edu:8080/render?target=#{whatData}&format=json"
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Get.new(uri.request_uri)
  request.basic_auth(@graphitePass, @graphitePass)
  request["Content-Type"] = "application/json"
  response = http.request(request)
  response.body
end

# Output a string of numbers or nill
def parse_that_graphite_data (whatData)
  if whatData 
    (whatData.delete "^1234567890\s").squeeze.lstrip
  end
end

def this_is_a_graphite_request? (call)
  if call
    call =~ /^[\S]*$/
  end
end

def can_I_spark_this? (astring)
    (astring.delete "1234567890\s").chomp.length == 0 
end

def spark_it (nums) 
  if nums =~ /[0-9]+/
    @ticks = %w[▁ ▂ ▃ ▄ ▅ ▆ ▇ █]
    values = nums.split.map { |x| x.to_f }
    min, range, scale = values.min, values.max - values.min, @ticks.length - 1
    if !(range == 0)
      values.map { |x| @ticks[(((x - min) / range) * scale).round] }.join
    else
      values.map { |x| @ticks[1] }.join
    end
  end
end

def loop_through_reply (reply)
    if reply
      howManySplits = 1.0
      1.upto(10) { |i|
        if reply.bytesize / i <= 452
          howManySplits = i
          break
        end
      }
      p reply.length
      p howManySplits
      regex = ".{" + (reply.delete(" ").length/howManySplits.to_f).ceil.to_s + "}"
      p Regexp.new regex
      p reply.scan(Regexp.new regex)
      reply.scan(Regexp.new regex).each { |x|
        @irc_server.puts "PRIVMSG #{@channel} :" + x
      }
    end
end

until @irc_server.eof? do
  msg = @irc_server.gets
  calc = msg.split(":")[2]
  result = nil
  if calc =~ /^!spark (.+)/  
    just_the_request = calc.gsub(/^!spark/, '').lstrip.chomp
    if this_is_a_graphite_request? just_the_request
      data = get_that_graphite_data just_the_request 
      just_the_request = parse_that_graphite_data data
    end
    if can_I_spark_this? just_the_request
      result = spark_it just_the_request
    end
    if result
      loop_through_reply result 
    end
  end
end
