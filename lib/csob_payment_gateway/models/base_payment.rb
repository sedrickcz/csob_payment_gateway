require 'rest-client'

module CsobPaymentGateway
  class BasePayment
    attr_reader :merchant_id, :gateway_url, :cart_items, :currency, :order_id,
                :total_price, :customer_id, :timestamp, :default_currency,
                :close_payment, :return_url, :description, :logger, :pay_id

    attr_accessor :response

    def initialize(attributes = {})
      attributes.each do |key, value|
        instance_variable_set(:"@#{key}", value) if self.respond_to?(key)
      end

      @merchant_id ||= CsobPaymentGateway.configuration.merchant_id.to_s
      @gateway_url ||= CsobPaymentGateway.configuration.gateway_url.to_s
      @return_url ||= CsobPaymentGateway.configuration.return_url.to_s
      @default_currency ||= CsobPaymentGateway.configuration.currency.to_s
      @close_payment ||= CsobPaymentGateway.configuration.close_payment.to_s

      @timestamp = Time.now.strftime('%Y%m%d%H%M%S')
    end

    def payment_init
      api_init_url = CsobPaymentGateway.configuration.urls['init']

      response = RestClient.post gateway_url + api_init_url, payment_data.to_json, { content_type: :json, accept: :json }
      self.response = JSON.parse(response)
    end

    def payment_process_url
      api_process_url = CsobPaymentGateway.configuration.urls['process']
      CGI.escapeHTML(gateway_url + api_process_url + get_data)
    end

    def payment_status
      api_status_url = CsobPaymentGateway.configuration.urls['status']

      response = RestClient.get gateway_url + api_status_url + get_data(false)
      self.response = JSON.parse(response)
    end

    def payment_close
      api_close_url = CsobPaymentGateway.configuration.urls['close']

      response = RestClient.put gateway_url + api_close_url, put_data.to_json, { content_type: :json, accept: :json }
      self.response = JSON.parse(response)
    end

    def payment_reverse
      api_reverse_url = CsobPaymentGateway.configuration.urls['reverse']

      response = RestClient.put gateway_url + api_reverse_url, put_data.to_json, { content_type: :json, accept: :json }
      self.response = JSON.parse(response)
    end

    def payment_refund
      api_refund_url = CsobPaymentGateway.configuration.urls['refund']

      response = RestClient.put gateway_url + api_refund_url, put_data.to_json, { content_type: :json, accept: :json }
      self.response = JSON.parse(response)
    end

    def verify_response
      text = [
          response['payId'],
          response['dttm'],
          response['resultCode'],
          response['resultMessage']
      ].map { |param| param.is_a?(Hash) ? '' : param.to_s }.join('|')

      text = text + '|' + response['paymentStatus'].to_s if response['paymentStatus'].present?

      text = text + '|' + response['authCode'].to_s if response['authCode'].present?

      text = text + '|' + response['merchantData'].to_s if response['merchantData'].present?

      CsobPaymentGateway::Crypt.verify(text, response['signature'])
    end

    def get_data(use_response = true)
      data_pay_id = (use_response ? response['payId'] : pay_id)
      text = [
          merchant_id,
          data_pay_id,
          timestamp
      ].map { |param| param.is_a?(Hash) ? '' : param.to_s }.join('|')

      signature = CsobPaymentGateway::Crypt.sign(text, 'GET')
      "#{merchant_id}/#{data_pay_id}/#{timestamp}/#{CGI.escape(signature)}"
    end

    def put_data
      data = {
          merchantId: merchant_id,
          payId: response['payId'],
          dttm: timestamp
      }

      text = [
          merchant_id,
          response['payId'],
          timestamp
      ].map { |param| param.is_a?(Hash) ? '' : param.to_s }.join('|')

      signature = CsobPaymentGateway::Crypt.sign(text, 'GET')
      data.merge(signature: signature)
    end

    def payment_data
      data = {
          merchantId: merchant_id,
          orderNo: order_id,
          dttm: timestamp,
          payOperation: 'payment',
          payMethod: 'card',
          totalAmount: total_price,
          currency: currency ? currency : default_currency,
          closePayment: close_payment,
          returnUrl: return_url,
          returnMethod: 'POST',
          cart: cart_items,
          description: description,
          merchantData: nil
      }
      data.merge!(customerId: customer_id) if customer_id.present? && customer_id.to_s != '0'
      data.merge!(language: 'EN')
      data.merge(signature: CsobPaymentGateway::Crypt.sign(data, 'POST'))
    end
  end
end
