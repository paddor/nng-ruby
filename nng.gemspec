# frozen_string_literal: true

require_relative 'lib/nng/version'

Gem::Specification.new do |spec|
  spec.name          = 'nng-ruby'
  spec.version       = NNG::VERSION
  spec.authors       = ['QingYi']
  spec.email         = ['qingyi.mail@gmail.com']

  spec.summary       = 'Ruby bindings for NNG (nanomsg-next-generation)'
  spec.description   = 'Complete Ruby bindings for NNG, a lightweight messaging library. ' \
                       'Supports all scalability protocols (Pair, Push/Pull, Pub/Sub, Req/Rep, ' \
                       'Surveyor/Respondent, Bus) and transports (TCP, IPC, Inproc, WebSocket, TLS). ' \
                       'Includes bundled libnng shared library.'
  spec.homepage      = 'https://github.com/Hola-QingYi/nng-ruby'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/Hola-QingYi/nng-ruby'
  spec.metadata['changelog_uri'] = 'https://github.com/Hola-QingYi/nng-ruby/blob/main/CHANGELOG.md'
  spec.metadata['documentation_uri'] = 'https://rubydoc.info/gems/nng-ruby'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,ext}/**/*', File::FNM_DOTMATCH).reject { |f| File.directory?(f) } +
    Dir.glob('examples/*.rb') +
    %w[README.md LICENSE CHANGELOG.md nng.gemspec Rakefile Gemfile]
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'ffi', '~> 1.15'

  # Development dependencies
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'rake-compiler', '~> 1.0'
  spec.add_development_dependency 'async'

  # Extension configuration (for capturing install-time options)
  # We use FFI so no actual compilation, but extconf.rb captures --with-nng-* options
  spec.extensions = ['ext/nng/extconf.rb']

  # Post-install message
  spec.post_install_message = <<~MSG
    ┌───────────────────────────────────────────────────────────┐
    │ Thank you for installing nng-ruby gem!                    │
    │                                                           │
    │ NNG (nanomsg-next-generation) Ruby bindings               │
    │ Version: #{NNG::VERSION.rjust(25)}                        │
    │                                                           │
    │ Quick start:                                              │
    │   require 'nng'                                           │
    │   socket = NNG::Socket.new(:pair1)                        │
    │   socket.listen("tcp://127.0.0.1:5555")                   │
    │                                                           │
    │ Documentation: https://rubydoc.info/gems/nng-ruby         │
    │ Examples: https://github.com/Hola-QingYi/nng-ruby         │
    └───────────────────────────────────────────────────────────┘
  MSG
end
