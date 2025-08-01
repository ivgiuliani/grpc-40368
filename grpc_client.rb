#!/usr/bin/env ruby

require 'grpc'
require_relative 'echo_pb'
require_relative 'echo_services_pb'

def ssl_creds
  GRPC::Core::ChannelCredentials.new(
    File.read('./ca.pem'),
    File.read('./client.key'),
    File.read('./client.pem')
  )
end

def call_creds
  GRPC::Core::CallCredentials.new(lambda { |args|
    { 'authorization' => "Bearer token_#{Time.now.to_i}" }
  })
end

def main
  puts "[client] versions grpc=#{GRPC::VERSION} ruby=#{RUBY_VERSION}"

  stub = Echo::EchoService::Stub.new(
    'localhost:50051',
    ssl_creds.compose(call_creds),
    channel_args: { GRPC::Core::Channel::SSL_TARGET => 'foo.test.google.fr' }
  )

  10_000.times do |i|
    request = Echo::EchoRequest.new(message: "test_#{Thread.current.object_id}_#{i}")
    stub.echo(request, deadline: Time.now + 5)

    puts "Progress: #{i} requests" if i % 100 == 0
  end
end

main
