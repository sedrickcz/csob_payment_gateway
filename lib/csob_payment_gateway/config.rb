require 'yaml'

module CsobPaymentGateway
  BASE_PATH = File.expand_path('../../../', __FILE__)

  def self.configure
    yield configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure_from_yaml(path)
    yaml = YAML.load_file(path)
    return unless yaml

    configuration.merchant_id = yaml['merchant_id']
    configuration.gateway_url = yaml['gateway_url']
    configuration.return_url = yaml['return_url']
    configuration.public_key = yaml['public_key']
    configuration.private_key = yaml['private_key']
    configuration.currency = yaml['currency']
    configuration.return_method_post = yaml['return_method_post']
    configuration.close_payment = yaml['close_payment']
    configuration.keys_directory = yaml['keys_directory']

    configuration
  end

  def self.configure_from_rails
    path = ::Rails.root.join('config', 'csob.yml')
    configure_from_yaml(path) if File.exists?(path)

    env = if defined?(::Rails) && ::Rails.respond_to?(:env)
            ::Rails.env.to_sym
          elsif defined?(::RAILS_ENV)
            ::RAILS_ENV.to_sym
          end
    configuration.environment ||= (env == :production) ? :production : :test

    warn "CSOB Payment Gateway wasn't properly configured." if CsobPaymentGateway.configuration.merchant_id.blank?
    configuration
  end

  class Configuration
    BASE_ATTRIBUTES = [:gateway_url, :public_key, :currency,
                       :return_method_post, :close_payment, :keys_directory]

    attr_accessor :environment, :merchant_id, :return_url, :private_key
    attr_writer   *BASE_ATTRIBUTES
    attr_reader :statuses, :urls

    def initialize
      config = YAML.load_file(File.join(BASE_PATH, 'config', 'config.yml'))
      @base = config['base']
      @statuses = config['statuses']
      @urls = config['urls']
    end

    BASE_ATTRIBUTES.each do |attribute|
      define_method attribute do
        instance_variable_get("@#{attribute}") || base[attribute.to_s]
      end
    end

    def base
      env = @environment.nil? ? 'test' : @environment.to_s
      @base[env]
    end
  end
end
