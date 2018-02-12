require 'openssl'
require 'base64'

module CsobPaymentGateway
  module Crypt
    extend self

    def prepare_data_to_sign(data, method)
      if method == 'POST'
        raise ArgumentError.new('Cart has more than 2 items') if data[:cart].size > 2
        cart_to_sign = data[:cart].reduce([]) { |acc, cart|
          acc << cart[:name]
          acc << cart[:quantity]
          acc << cart[:amount]
          acc << cart[:description]
          acc
        }.map { |param| param.is_a?(Hash) ? '' : param.to_s }.join('|')

        data_to_sign = [
            data[:merchantId],
            data[:orderNo],
            data[:dttm],
            data[:payOperation],
            data[:payMethod],
            data[:totalAmount],
            data[:currency],
            data[:closePayment],
            data[:returnUrl],
            data[:returnMethod],
            cart_to_sign,
            data[:description]
        ].map { |param| param.is_a?(Hash) ? '' : param.to_s }.join('|')


        merchant_data = data[:merchantData]
        data_to_sign = "#{data_to_sign}|#{merchant_data}" if merchant_data.present?

        customer_id = data[:customerId]
        data_to_sign = "#{data_to_sign}|#{customer_id}" if customer_id.present? && customer_id.to_s != '0'

        data_to_sign = "#{data_to_sign}|#{data[:language]}"

        data_to_sign = data_to_sign.chop if data_to_sign[-1] == '|'
      elsif method == 'GET'
        data_to_sign = data
      else
        raise ArgumentError.new "Unknown method: '#{method}' for data preparation"
      end
      data_to_sign
    end

    def private_key
      key = CsobPaymentGateway.configuration.private_key.to_s
      return key if key.start_with?('-----BEGIN RSA PRIVATE KEY-----')

      File.read ::Rails.root.join(CsobPaymentGateway.configuration.keys_directory.to_s, key)
    end

    def public_key
      File.read ::Rails.root.join(CsobPaymentGateway::BASE_PATH, 'keys', CsobPaymentGateway.configuration.public_key.to_s)
    end

    def sign(data, method)
      data_to_sign = prepare_data_to_sign(data, method)
      key = OpenSSL::PKey::RSA.new(private_key)

      digest = OpenSSL::Digest::SHA1.new
      signature = key.sign(digest, data_to_sign)

      Base64.encode64(signature).gsub("\n", '')
    end

    def verify(data, signature_64)
      key = OpenSSL::PKey::RSA.new(public_key)
      signature = Base64.decode64(signature_64)
      digest = OpenSSL::Digest::SHA1.new
      if key.verify digest, signature, data
        'Valid'
      else
        'Invalid'
      end
    end
  end
end
