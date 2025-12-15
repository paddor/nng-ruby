# frozen_string_literal: true

module NNG
  # NNG message wrapper
  class Message
    attr_reader :msg_ptr

    # @param ptr [::FFI::MemoryPointer]
    def self.from_pointer(ptr)
      new_msg = allocate
      new_msg.instance_variable_set(:@msg, ptr.read_pointer)
      new_msg.instance_variable_set(:@msg_ptr, ptr)
      new_msg.instance_variable_set(:@freed, false)
      new_msg
    end

    # Create a new message
    # @param size [Integer] initial size
    def initialize(size: 0)
      @msg_ptr = ::FFI::MemoryPointer.new(:pointer)
      ret = FFI.nng_msg_alloc(@msg_ptr, size)
      FFI.check_error(ret, "Allocate message")
      @msg = @msg_ptr.read_pointer
      @freed = false
    end

    # Append data to message body
    # @param data [String] data to append
    # @return [self]
    def append(data)
      check_freed
      data_str = data.to_s
      data_ptr = ::FFI::MemoryPointer.new(:uint8, data_str.bytesize)
      data_ptr.put_bytes(0, data_str)

      ret = FFI.nng_msg_append(@msg, data_ptr, data_str.bytesize)
      FFI.check_error(ret, "Append to message")
      self
    end

    # Insert data at the beginning of message body
    # @param data [String] data to insert
    # @return [self]
    def insert(data)
      check_freed
      data_str = data.to_s
      data_ptr = ::FFI::MemoryPointer.new(:uint8, data_str.bytesize)
      data_ptr.put_bytes(0, data_str)

      ret = FFI.nng_msg_insert(@msg, data_ptr, data_str.bytesize)
      FFI.check_error(ret, "Insert to message")
      self
    end

    # Get message body
    # @return [String] message body
    def body
      check_freed
      body_ptr = FFI.nng_msg_body(@msg)
      length = FFI.nng_msg_len(@msg)
      body_ptr.read_bytes(length)
    end

    def body=(new_body)
      clear
      append new_body
    end

    # Get message body length
    # @return [Integer] length in bytes
    def length
      check_freed
      FFI.nng_msg_len(@msg)
    end
    alias size length

    # Get message header
    # @return [String] message header
    def header
      check_freed
      header_ptr = FFI.nng_msg_header(@msg)
      length = FFI.nng_msg_header_len(@msg)
      header_ptr.read_bytes(length)
    end

    def header=(new_header)
      header_clear
      header_append new_header
    end

    # Get message header length
    # @return [Integer] length in bytes
    def header_length
      check_freed
      FFI.nng_msg_header_len(@msg)
    end

    # Append data to message header
    # @param data [String] data to append
    # @return [self]
    def header_append(data)
      check_freed
      data_str = data.to_s
      data_ptr = ::FFI::MemoryPointer.new(:uint8, data_str.bytesize)
      data_ptr.put_bytes(0, data_str)

      ret = FFI.nng_msg_header_append(@msg, data_ptr, data_str.bytesize)
      FFI.check_error(ret, "Append to message header")
      self
    end

    # Clear message body
    # @return [self]
    def clear
      check_freed
      FFI.nng_msg_clear(@msg)
      self
    end

    # Clear message header
    # @return [self]
    def header_clear
      check_freed
      FFI.nng_msg_header_clear(@msg)
      self
    end

    # Duplicate message
    # @return [Message] duplicated message
    def dup
      check_freed
      dup_ptr = ::FFI::MemoryPointer.new(:pointer)
      ret = FFI.nng_msg_dup(dup_ptr, @msg)
      FFI.check_error(ret, "Duplicate message")

      new_msg = self.class.allocate
      new_msg.instance_variable_set(:@msg, dup_ptr.read_pointer)
      new_msg.instance_variable_set(:@msg_ptr, dup_ptr)
      new_msg.instance_variable_set(:@freed, false)
      new_msg
    end

    # Free the message
    # @return [nil]
    def free
      return if @freed
      FFI.nng_msg_free(@msg)
      @freed = true
      nil
    end

    # Check if message is freed
    # @return [Boolean]
    def freed?
      @freed
    end

    # Get the internal message pointer (for use with send/recv)
    # @return [FFI::Pointer]
    def to_ptr
      @msg
    end

    private

    def check_freed
      raise StateError, "Message has been freed" if @freed
    end
  end
end
