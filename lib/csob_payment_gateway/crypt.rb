require 'openssl'
require 'base64'

module CsobPaymentGateway
  module Crypt
    extend self

    def prepare_data_to_sign(data, method)
      if method == 'POST'
        cart_to_sign = [
          data[:cart][0][:name],
          data[:cart][0][:quantity],
          data[:cart][0][:amount],
          data[:cart][0][:description]
        ].map { |param| param.is_a?(Hash) ? '' : param.to_s }.join('|')


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
        data_to_sign = "#{data_to_sign}|#{merchant_data}" unless merchant_data.nil?

        customer_id = data[:customerId]
        data_to_sign = "#{data_to_sign}|#{customer_id}" if !customer_id.nil? and customer_id.to_s != '0'

        data_to_sign = "#{data_to_sign}|#{data[:language]}"

        data_to_sign = data_to_sign.chop if data_to_sign[-1] == '|'
      elsif method == 'GET'
        data_to_sign = data
      end

      data_to_sign
    end

    def private_key_url
      ::Rails.root.join(CsobPaymentGateway.configuration.keys_directory.to_s, CsobPaymentGateway.configuration.private_key.to_s)
    end

    def public_key_url
      ::Rails.root.join(CsobPaymentGateway.configuration.keys_directory.to_s, CsobPaymentGateway.configuration.public_key.to_s)
    end

    def sign(data, method)
      data_to_sign = prepare_data_to_sign(data, method)
      key = OpenSSL::PKey::RSA.new(File.read(private_key_url))

      digest = OpenSSL::Digest::SHA1.new
      signature = key.sign(digest, data_to_sign)

      Base64.encode64(signature).gsub("\n", '')
    end

    def verify(data, signature_64)
      key = OpenSSL::PKey::RSA.new(File.read(public_key_url))
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
