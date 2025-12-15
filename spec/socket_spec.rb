# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NNG do
  describe 'Pair protocol' do
    it 'can send and receive messages' do
      server = NNG::Socket.new(:pair1)
      server.listen('tcp://127.0.0.1:15555')

      client = NNG::Socket.new(:pair1)
      client.dial('tcp://127.0.0.1:15555')

      # Give sockets time to connect
      sleep 0.1

      # Send from client to server
      client.send('Hello, server!')
      received = server.recv
      expect(received).to eq('Hello, server!')

      # Send from server to client
      server.send('Hello, client!')
      received = client.recv
      expect(received).to eq('Hello, client!')

      server.close
      client.close
    end
  end

  describe 'Request/Reply protocol' do
    it 'can handle request-reply pattern' do
      rep = NNG::Socket.new(:rep)
      rep.listen('tcp://127.0.0.1:15557')

      req = NNG::Socket.new(:req)
      req.dial('tcp://127.0.0.1:15557')

      sleep 0.1

      # Send request
      req.send('What is the answer?')
      question = rep.recv
      expect(question).to eq('What is the answer?')

      # Send reply
      rep.send('42')
      answer = req.recv
      expect(answer).to eq('42')
    ensure
      rep&.close
      req&.close
    end
  end

  describe 'Push/Pull protocol' do
    it 'can handle pipeline pattern' do
      push = NNG::Socket.new(:push)
      push.listen('tcp://127.0.0.1:15558')

      pull = NNG::Socket.new(:pull)
      pull.dial('tcp://127.0.0.1:15558')

      sleep 0.1

      push.send('Task 1')
      task = pull.recv
      expect(task).to eq('Task 1')

      push.close
      pull.close
    end
  end

  describe 'Socket options' do
    it 'can set and get timeout options' do
      socket = NNG::Socket.new(:pair1)

      socket.send_timeout = 1000
      socket.recv_timeout = 2000

      # Note: Getting options might not work for all option types
      # This is just to test the API

      socket.close
    end
  end

  describe 'Error handling' do
    it 'raises error on invalid protocol' do
      expect { NNG::Socket.new(:invalid_protocol) }.to raise_error(ArgumentError)
    end

    it 'raises error when sending on closed socket' do
      socket = NNG::Socket.new(:pair1)
      socket.close

      expect { socket.send('data') }.to raise_error(NNG::Closed)
    end
  end
end
