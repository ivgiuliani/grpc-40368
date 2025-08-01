#!/usr/bin/env ruby

require 'grpc'
require_relative 'echo_pb'
require_relative 'echo_services_pb'

class EchoServer < Echo::EchoService::Service
  def echo(request, _call)
    puts "[server] msg: #{request.message}"

    response = if request.message.downcase == 'ping'
                 'pong'
               else
                 "echo: #{request.message}"
               end

    Echo::EchoReply.new(message: response)
  end
end

def create_server_credentials
  GRPC::Core::ServerCredentials.new(
    File.read('./ca.pem'),
    [{ private_key: File.read('./server1.key'), cert_chain: File.read('./server1.pem') }],
    true
  )
end

def main
  puts "[server] versions grpc=#{GRPC::VERSION} ruby=#{RUBY_VERSION}"

  server = GRPC::RpcServer.new
  port = '0.0.0.0:50051'

  server.add_http2_port(port, create_server_credentials)
  server.handle(EchoServer)

  puts "gRPC server listening on #{port}"
  server.run_till_terminated_or_interrupted([1, 'int', 'SIGTERM'])
end

main
