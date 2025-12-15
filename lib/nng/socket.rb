# frozen_string_literal: true

require_relative 'protocols'

module NNG
  # High-level socket interface
  class Socket
    attr_reader :socket

    # Create a new socket
    # @param protocol [Symbol] protocol name (:pair0, :pair1, :push, :pull, :pub, :sub, :req, :rep, :surveyor, :respondent, :bus)
    # @param raw [Boolean] open in raw mode
    def initialize(protocol, raw: false)
      @socket = Protocols.open_socket(protocol, raw: raw)
      @closed = false
    end

    # Listen on an address
    # @param url [String] URL to listen on (e.g., "tcp://0.0.0.0:5555", "ipc:///tmp/test.sock")
    # @param flags [Integer] optional flags
    # @return [self]
    def listen(url, flags: 0)
      check_closed
      ret = FFI.nng_listen(@socket, url, nil, flags)
      FFI.check_error(ret, "Listen on #{url}")
      self
    end

    # Dial (connect) to an address
    # @param url [String] URL to connect to (e.g., "tcp://127.0.0.1:5555")
    # @param flags [Integer] optional flags
    # @return [self]
    def dial(url, flags: 0)
      check_closed
      ret = FFI.nng_dial(@socket, url, nil, flags)
      FFI.check_error(ret, "Dial to #{url}")
      self
    end

    # Send data
    # @param data [String] data to send
    # @param flags [Integer] optional flags (e.g., FFI::NNG_FLAG_NONBLOCK)
    # @return [self]
    def send(data, flags: 0)
      check_closed
      data_str = data.to_s
      data_ptr = ::FFI::MemoryPointer.new(:uint8, data_str.bytesize)
      data_ptr.put_bytes(0, data_str)

      ret = FFI.nng_send(@socket, data_ptr, data_str.bytesize, flags)
      FFI.check_error(ret, "Send data")
      self
    end


    # Send message
    # @param msg [Message] message to send
    # @param flags [Integer] optional flags (e.g., FFI::NNG_FLAG_NONBLOCK)
    # @return [self]
    def sendmsg(msg, flags: 0)
      check_closed

      ret = FFI.nng_sendmsg(@socket, msg, flags)
      FFI.check_error(ret, "Send message")
      self
    end


    # Receive data
    # @param flags [Integer] optional flags (e.g., FFI::NNG_FLAG_NONBLOCK)
    # @return [String] received data
    def recv(flags: FFI::NNG_FLAG_ALLOC)
      check_closed

      buf_ptr = ::FFI::MemoryPointer.new(:pointer)
      size_ptr = ::FFI::MemoryPointer.new(:size_t)

      ret = FFI.nng_recv(@socket, buf_ptr, size_ptr, flags)
      FFI.check_error(ret, "Receive data")

      # Read the data
      response_buf = buf_ptr.read_pointer
      response_size = size_ptr.read(:size_t)
      data = response_buf.read_bytes(response_size)

      # Free NNG-allocated memory
      FFI.nng_free(response_buf, response_size)

      data
    end

    def recvmsg(flags: 0)
      check_closed

      msg_ptr = ::FFI::MemoryPointer.new(:pointer)
      ret = FFI.nng_recvmsg(@socket, msg_ptr, flags)
      FFI.check_error(ret, "Receive message")

      Message.from_pointer msg_ptr
    end

    # Set socket option
    # @param name [String] option name
    # @param value [Object] option value
    # @return [self]
    def set_option(name, value)
      check_closed

      case value
      when true, false
        ret = FFI.nng_socket_set_bool(@socket, name, value)
      when Integer
        if value >= 0 && value <= 2**31 - 1
          ret = FFI.nng_socket_set_int(@socket, name, value)
        else
          ret = FFI.nng_socket_set_uint64(@socket, name, value)
        end
      when String
        ret = FFI.nng_socket_set_string(@socket, name, value)
      else
        raise ArgumentError, "Unsupported option value type: #{value.class}"
      end

      FFI.check_error(ret, "Set option #{name}")
      self
    end

    # Get socket option
    # @param name [String] option name
    # @param type [Symbol] expected type (:bool, :int, :size, :uint64, :string, :ms)
    # @return [Object] option value
    def get_option(name, type: :int)
      check_closed

      # :ms is actually :int32 (nng_duration)
      ptr_type = type == :ms ? :int32 : type
      value_ptr = ::FFI::MemoryPointer.new(ptr_type)

      ret = case type
            when :bool
              FFI.nng_socket_get_bool(@socket, name, value_ptr)
            when :int
              FFI.nng_socket_get_int(@socket, name, value_ptr)
            when :size
              FFI.nng_socket_get_size(@socket, name, value_ptr)
            when :uint64
              FFI.nng_socket_get_uint64(@socket, name, value_ptr)
            when :ms
              FFI.nng_socket_get_ms(@socket, name, value_ptr)
            when :string
              FFI.nng_socket_get_string(@socket, name, value_ptr)
            else
              raise ArgumentError, "Unknown option type: #{type}"
            end

      FFI.check_error(ret, "Get option #{name}")

      if type == :string
        str_ptr = value_ptr.read_pointer
        result = str_ptr.read_string
        FFI.nng_strfree(str_ptr)
        result
      else
        value_ptr.read(ptr_type)
      end
    end

    # Set send timeout
    # @param ms [Integer] timeout in milliseconds
    # @return [self]
    def send_timeout=(ms)
      set_option_ms('send-timeout', ms)
    end

    # Set receive timeout
    # @param ms [Integer] timeout in milliseconds
    # @return [self]
    def recv_timeout=(ms)
      set_option_ms('recv-timeout', ms)
    end

    # Set timeout option
    # @param name [String] option name
    # @param ms [Integer] timeout in milliseconds
    # @return [self]
    def set_option_ms(name, ms)
      check_closed
      ret = FFI.nng_socket_set_ms(@socket, name, ms)
      FFI.check_error(ret, "Set option #{name}")
      self
    end

    # Get socket ID
    # @return [Integer] socket ID
    def id
      FFI.nng_socket_id(@socket)
    end

    # Close the socket
    # @return [nil]
    def close
      return if @closed
      FFI.nng_close(@socket)
      @closed = true
      nil
    end

    # Check if socket is closed
    # @return [Boolean]
    def closed?
      @closed
    end

    private

    def check_closed
      raise Closed, "Socket is closed" if @closed
    end
  end
end
