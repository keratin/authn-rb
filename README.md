# Keratin AuthN

Keratin AuthN is an authentication service that keeps you in control of the experience without forcing you to be an expert in web security.

This gem provides utilities to help integrate with a Ruby application. You may also be interested in keratin/authn-js for frontend integration.

[![Gem Version](https://badge.fury.io/rb/keratin-authn.svg)](http://badge.fury.io/rb/keratin-authn) [![Build Status](https://travis-ci.org/keratin/authn-rb.svg?branch=master)](https://travis-ci.org/keratin/authn-rb)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'keratin-authn'
```

## Usage

Configure your integration from a file such as `config/initializers/keratin.rb`:

```ruby
Keratin::AuthN.config.tap do |config|
  # The base URL of your Keratin AuthN service
  config.issuer = 'https://authn.myapp.com'

  # The domain of your application
  config.audience = 'myapp.com'

  # HTTP basic auth for using AuthN's private endpoints
  config.username = 'secret'
  config.password = 'secret'
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

* `Keratin.authn.lock(account_id)`: will lock an account, revoking all sessions (when they time out)
  and disallowing any new logins. Intended for user moderation actions.
* `Keratin.authn.unlock(account_id)`: will unlock an account, restoring normal functionality.
* `Keratin.authn.archive(account_id)`: will wipe all personal information, including username and
  password. Intended for user deletion routine.

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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/keratin/authn-rb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

