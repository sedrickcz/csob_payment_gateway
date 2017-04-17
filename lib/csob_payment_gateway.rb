require 'csob_payment_gateway/config'
require 'csob_payment_gateway/crypt'

require 'csob_payment_gateway/models/base_payment'

require 'csob_payment_gateway/railtie' if defined?(::Rails) && ::Rails::VERSION::MAJOR >= 3
