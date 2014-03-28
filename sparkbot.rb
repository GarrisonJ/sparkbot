#!/usr/bin/env ruby
# encoding: utf-8
require "socket"
require "openssl"
require "net/http"
require 'json'

# Variables
@help_msg     = "!spark 1 2 3 4 5 6"
@server       = "irc.cat.pdx.edu"
@port         = "6697"
@nick         = "spark"
@channel      = "#test-test"
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

until @irc_server.eof? do
  msg = @irc_server.gets
  p msg
  if msg =~ /^PING/
    @irc_server.puts "PONG" 
  end
  calc = msg.split(":")[2]
  result = nil
  if calc != nil
    if calc =~ /^!spark (.+)/  
      nums = calc.gsub(/^!spark/, '').lstrip.chomp
      if nums == "help"
        @irc_server.puts "PRIVMSG #{@channel} :" + @help_msg	
      elsif can_I_spark_this? nums
        result = spark_it nums
      end
      if result
        @irc_server.puts "PRIVMSG #{@channel} :" + result
      end
    end
  end
end
