# Keratin AuthN

Keratin AuthN is an authentication service that keeps you in control of the experience without forcing you to be an expert in web security.

This gem provides utilities to help integrate with a Ruby application. You may also be interested in keratin/authn-js for frontend integration.

[![Gem Version](https://badge.fury.io/rb/keratin-authn.svg)](http://badge.fury.io/rb/keratin-authn) [![Build Status](https://travis-ci.org/keratin/authn-rb.svg?branch=master)](https://travis-ci.org/keratin/authn-rb) [![Coverage Status](https://coveralls.io/repos/github/keratin/authn/badge.svg?branch=master)](https://coveralls.io/github/keratin/authn?branch=master)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'keratin-authn'
```

## Usage

Configure your integration from a file such as `config/initializers/keratin.rb`:

```ruby
Keratin::AuthN.config.tap do |config|
  # The AUTHN_URL of your Keratin AuthN server. This will be used to verify tokens created by AuthN,
  # and will also be used for API calls unless `config.authn_url` is also set (see below).
  config.issuer = 'https://authn.myapp.com'

  # The domain of your application (no protocol). This domain should be listed in the APP_DOMAINS of
  # your Keratin AuthN server.
  config.audience = 'myapp.com'

  # Credentials for AuthN's private endpoints. These will be used to execute admin actions using the
  # `Keratin.authn` client provided by this library.
  #
  # TIP: make them extra secure in production!
  config.username = 'secret'
  config.password = 'secret'

  # OPTIONAL: enables debugging for the JWT verification process
  # config.logger   = Rails.logger

  # OPTIONAL: Send private API calls to AuthN using private network routing. This can be necessary
  # if your environment has a firewall to limit public endpoints.
  # config.authn_url = 'https://authn.internal.dns/
end
```

### Reading the Session

Use `Keratin::AuthN.subject_from(params[:authn])` to fetch an `account_id` from the session if and
only if the session is valid.

### Logging Out

Send users to `Keratin::AuthN.logout_url(return_to: some_path)` to log them out from the AuthN
server. If you use [keratin/authn-js](https://github.com/keratin/authn-js), you might prefer the
logout functionality there as it can also take care of deleting the cookie.

### Modifying Accounts

* `Keratin.authn.update(account_id, username: 'new@example.tech')`: will synchronize an email change
  with the AuthN server.
* `Keratin.authn.lock(account_id)`: will lock an account, revoking all sessions (when they time out)
  and disallowing any new logins. Intended for user moderation actions.
* `Keratin.authn.unlock(account_id)`: will unlock an account, restoring normal functionality.
* `Keratin.authn.archive(account_id)`: will wipe all personal information, including username and
  password. Intended for user deletion routine.
* `Keratin.authn.expire_password(account_id)`: will force the account to reset their password on the
  next login, and revoke all current sessions. Intended for use when password is deemed insecure or
  otherwise expired.

### Other

* `Keratin.authn.import(username: user.email, password: user.password, locked: false)`: will create
  an account in Keratin. Intended for importing data from a legacy system. Returns an `account_id`,
  or raises on validation errors.

### Example: Sessions

You should store the token in a cookie (the [keratin/authn-js](https://github.com/keratin/authn-js)
integration can do this automatically) and continue using it to verify a logged-in session:

```ruby
class ApplicationController
  private

  def logged_in?
    !! current_account_id
  end

  def current_user
    return @current_user if defined? @current_user
    @current_user = User.find_by_account_id(current_account_id)
  end

  def current_account_id
    Keratin::AuthN.subject_from(cookies[:authn])
  end
end
```

### Example: Signup

```ruby
class UsersController
  def create
    @user = User.new(params.require(:user).permit(:name, :email))
    @user.account_id = current_account_id

    # ...
  end
end
```

### Example: Login

```ruby
class SessionsController
  def create
    @user = current_user

    # ...
  end
end
```

### Example: Multiple Domains

When working with multiple frontend domains it may be beneficial to use a referrer header as your audience instead of a static configuration. You can do this by providing an additional parameter to the `subject_from` method.

```ruby
class ApplicationController
  private

  def current_user
    return @current_user if defined? @current_user
    @current_user = User.find_by_account_id(current_account_id)
  end

  def current_account_id
    Keratin::AuthN.subject_from(cookies[:authn], audience: URI.parse(request.referer).host)
  end
end
```

## Testing Your App

AuthN provides helpers for working with tokens in your application's controller and integration tests.

In your `test/test_helper.rb` or equivalent:

```ruby
# Configuring AuthN to use the MockKeychain will stop your tests from attempting to connect to the
# remote issuer during tests.
Keratin::AuthN.signature_verifier = Keratin::AuthN::MockKeychain.new

# Including the Test::Helpers module grants access to `id_token_for(user.account_id)`, so that you
# can test your system with real tokens.
module ActionDispatch
  class IntegrationTest
    include Keratin::AuthN::Test::Helpers
  end
end
```

## Developing AuthN

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/keratin/authn-rb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.
