# Mediate

A simple mediator implementation for Ruby inspired by [Mediatr](https://github.com/jbogard/MediatR).

Decouple application components by sending a request through the mediator and receiving a response from a handler, instead of directly calling methods on imported classes.

Supports request/response, notifications (i.e., events), pre- and post-request handler decorators, and error handling.

- [Installation](#installation)
- [Usage](#usage)
  - [Requests](#requests)
    - [Implicit handler declaration](#implicit-handler-declaration)
    - [Request polymorphism](#request-polymorphism)
    - [Pre- and post-request behaviors](#pre--and-post-request-behaviors)
  - [Notifications](#notifications)
  - [Error handlers](#error-handlers)
  - [Testing](#testing)
    - [Testing implicit request handlers](#testing-implicit-request-handlers)
  - [Using with Rails](#using-with-rails)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## Installation

Add this to your Gemfile:

```ruby
gem "mediate"
```

And run:

```sh
bundle
```

## Usage

There are two types of messages that can be sent through the mediator:

- Requests (`Mediate::Request`) have exactly one handler (`Mediate::RequestHandler`), which returns a response.
- Notifications (`Mediate::Notification`) are `publish`ed to zero or more handlers (`Mediate::NotificationHandler`).  Nothing is returned to the caller.

### Requests

To define a request, declare a class that inherits from `Mediate::Request`.

```ruby
class Ping < Mediate::Request
    attr_reader :message

    def initialize(message)
        @message = message
        super()
    end
end
```

To register a handler for it, declare a class that inherits from `Mediate::RequestHandler`, call the class method `handles` passing the class of requests that it handles, and implement the `handle` method.

```ruby
class PingHandler < Mediate::RequestHandler
    handles Ping

    def handle(request)
        "Received: #{request.message}"
    end
end
```

To send a request, pass it to `Mediate.dispatch`.  The mediator will resolve the registered handler according to the request type and return the result of its `handle` method.

```ruby
response = Mediate.dispatch(Ping.new('hello'))
puts response # 'Received: hello'
```

The only requirement for `RequestHandler`s, besides implementing the `handle` method, is that __they should have a constructor that can be called without arguments__.  This applies to all `*Handler` and `*Behavior` classes.  For example, the following would work because all constructor parameters have default values.

```ruby
class PingHandler < Mediate::RequestHandler
    handles Ping

    def initialize(service = SomeService.new)
        @service = service
    end

    def handle(request)
        @service.call("Received: #{request.message}")
    end
end
```

Note that only one handler can be registered for a particular request class; attempting to register another handler for `Ping` would raise a `RequestHandlerAlreadyExistsError`.

#### Implicit handler declaration

For simple handlers, you can skip the explicit `RequestHandler` declaration above and instead pass a lambda to `Request.handle_with`.

```ruby
class Ping < Mediate::Request
    attr_reader :message

    def initialize(message)
        @message = message
        super()
    end
    # This will have the same behavior as the PingHandler declaration above.
    handle_with ->(request) { "Received: #{request.message}" }
end

response = Mediate.dispatch(Ping.new('hello'))
puts response # 'Received: hello'
```

Behind the scenes, this defines a `Ping::Handler` class that calls the given lambda in its `handle` method.  For testing purposes, you can get an instance of this handler class by calling `Mediate::Request.create_implicit_handler` (see [Testing implicit request handlers](#testing-implicit-request-handlers)).

#### Request polymorphism

The mediator resolves handlers by moving up the request's inheritance chain until it finds a registered handler for that class.  For example, subclasses of `Ping` would be handled by `PingHandler`.

```ruby
class SubPing < Ping; end
puts Mediate.dispatch(SubPing.new('howdy')) # 'Received: howdy'
```

Unless we registered a handler for `SubPing` explicitly.

```ruby
class SubPing < Ping
    handle_with ->(request) { "Received from SubPing: #{request.message}" }
end
puts Mediate.dispatch(SubPing.new('howdy')) # 'Received from SubPing: howdy'
```

#### Pre- and post-request behaviors

For certain cases, you will want code to run before or after a request is handled, e.g., logging, authorization, validation, backwards compatibility, etc.  Effectively, these act as decorators for your request handler(s).  You can register `Mediate::PrerequestBehavior`s and `Mediate::PostrequestBehavior`s for this purpose.

Behaviors will run for any request that is or inherits from the request class registered.  For example, if you wanted a behavior to run for every request, you could register it with `handles Mediate::Request`.  Unlike request handlers, multiple behaviors can be registered for the same request class.

```ruby
class PreLoggingBehavior < Mediate::PrerequestBehavior
    handles Mediate::Request # This will be called before all request handlers

    def initialize(logger = Logger)
        @logger = logger
    end

    def handle(request)
        @logger.info("Received request: #{request}")
    end
end

class PingValidator < Mediate::PrerequestBehavior
    handles Ping # Will be called before Ping requests or any subclasses of Ping

    def handle(request)
        raise "Ping is missing message" if request.message.nil?
    end
end

class PostLoggingBehavior < Mediate::PostrequestBehavior
    handles Mediate::Request # Will be called after all request handlers

    def initialize(logger = Logger)
        @logger = logger
    end

    def handle(request, result)
        @logger.info("Request: #{request} resulted in #{result}")
    end
end
```

### Notifications

Notifications are messages that can be passed to multiple handlers.  To publish a notification, call `Mediate.publish(notification)`.  No response is returned from `publish`.

Define a notification by inheriting from `Mediate::Notification`.

```ruby
class PostCreated < Mediate::Notification
    attr_reader :post

    def initialize(post)
        @post = post
    end
end
```

Declare and register a handler by inheriting from `Mediate::NotificationHandler`, calling `handles` with the notification class to handle, and implementing the `handle` method.

```ruby
class PostCreatedHandler < Mediate::NotificationHandler
    handles PostCreated
    
    def handle(notification)
        # do something with PostCreated notification...
    end
end
```

Like [request behaviors](#pre--and-post-request-behaviors), all notification handlers that are registered for a notification class or any of its superclasses will be called when a given notification is published.  For example, a handler that `handles Mediate::Notification` will be called when any notification is published.  Handlers will be called in order of inheritance of their registered notifications from subclass to superclass (and in order of registration if the registered notification class is the same).

### Error handlers

When a request or notification handler raises a `StandardError`, the mediator will find all `ErrorHandler`s that have been registered for that request/notification class (or superclasses) and the exception class (or superclasses).

```ruby
# This will be called on any StandardError from any request or notification handler
class GlobalErrorHandler < Mediate::ErrorHandler
    handles StandardError, Mediate::Request
    handles StandardError, Mediate::Notification

    # dispatched is the Request or Notification
    def handle(dispatched, exception, state)
        # do something...
    end
end

# This would get called when ActiveRecord::RecordNotFound is raised while handling a QueryRequest
class NotFoundHandler < Mediate::ErrorHandler
    handles ActiveRecord::RecordNotFound, QueryRequest

    def handle(dispatched, exception, state)
        # ...
    end
end
```

Note that the exception class passed to handles must be `StandardError` or a subclass of it.

The `state` parameter of `handle` is a `Mediate::ErrorHandlerState` instance that represents whether the exception has been "handled" or not.  By calling `set_as_handled` and optionally passing in a result, all subsequent error handlers will be skipped and the given result will be returned to the caller of `dispatch` (obviously, if the error was raised from a notification handler, nothing will be returned).

```ruby
class ValidationErrorHandler < Mediate::ErrorHandler
    handles ActiveRecord::RecordInvalid, Mediate::Request

    def handle(dispatched, exception, state)
        state.set_as_handled(exception.record.errors)
    end
end
```

### Testing

All of the handler and behavior classes described above are just normal Ruby classes.  You can instantiate them and call their `handle` methods to test as you normally would.

Special consideration is only required when testing paths that invoke methods on the mediator itself (e.g., `Mediate.dispatch` or `Mediate.publish`), since it is designed to be a singleton.  The mediator's registration methods are idempotent (and thread-safe), so re-registering handlers should not cause issues.  However, if you want to ensure that you are not sharing state between tests, you can call the `Mediate.mediator.reset` method in your test setup or clean-up to remove all handler and behavior registrations.

#### Testing implicit request handlers

How can you test a request handler defined using `handle_with` and a lambda like the following?

```ruby
class ExampleRequest < Mediate::Request
    handle_with lambda { |request|
        # ....
    }
end
```

The `handle_with` method defines a handler class and registers it with the mediator to handle the containing request class.  `Mediate::Request` provides a convenience method, `create_implicit_handler`, that creates an instance of this handler class.  You can then call `handle` on that method like normal to test it.

```ruby
RSpec.describe "ExampleRequestHandler" do
    let(:handler) { ExampleRequest.create_implicit_handler }

    it "returns something" do
        expect(handler.handle(ExampleRequest.new)).to be_truthy
    end
end
```

### Using with Rails

TODO

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome in this repo.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
