# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NNG do
  describe '.version' do
    it 'returns the gem version' do
      expect(NNG.version).to eq(NNG::VERSION)
    end
  end

  describe '.lib_version' do
    it 'returns the NNG library version' do
      expect(NNG.lib_version).to match(/\d+\.\d+\.\d+/)
    end
  end
end
