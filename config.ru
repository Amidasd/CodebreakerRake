# frozen_string_literal: true

require_relative 'dependency'

use Rack::Reloader
use Rack::Static, urls: ['/assets'], root: 'app/views'
use Rack::Session::Cookie, key: 'rack.session',
                           path: '/',
                           expire_after: 2_592_000,
                           secret: 'secret_password'

run CodebreakerRake
