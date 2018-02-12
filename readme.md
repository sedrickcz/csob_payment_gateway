# Csob payment gateway

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'csob_payment_gateway'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install csob_payment_gateway

## Usage

### Initialize

config/initializers/csob.rb

```ruby
CsobPaymentGateway.configure do |config|
  config.close_payment        = true
  config.currency             = 'CZK'
  config.merchant_id          = "M1MIPS0459"
  # config.environment        = Rails.env.production? ? :production : :test
  # config.keys_directory     = "private/keys"
  # config.private_key        = "rsa_M1MIPS0459.key"
  config.private_key          = "-----BEGIN RSA PRIVATE.........."
  # config.return_method_post = true
  # config.return_url         = "http://localhost:3000/orders/process_order"
end
```

or

config/csob.yml

```yml
close_payment: "true"
currency: "CZK"
environment: :test
gateway_url: "https://iapi.iplatebnibrana.csob.cz/api/v1.7"
keys_directory: "private/keys"
merchant_id: "M1MIPS0459"
private_key: "rsa_M1MIPS0459.key"
public_key: "mips_iplatebnibrana.csob.cz.pub"
return_method_post: true
return_url: "http://localhost:3000/orders/process_order"
```

### Payment

```ruby
payment = CsobPaymentGateway::BasePayment.new(
  total_price: 60_000,
  cart_items:  [
    { name: 'Item 1',   quantity: 1, amount: 50_000, description: 'Item 1' },
    { name: 'Shipping', quantity: 1, amount: 10_000, description: 'Shipping' }
  ],
  order_id:    1234,
  description: 'Order from your-eshop.com - Total price 600 CZK',
  customer_id: 1234
)

init   = payment.payment_init
pay_id = init['payId']

redirect_to payment.payment_process_url
```
