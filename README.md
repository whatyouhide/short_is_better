# Short is better (isn't it?)

short-is-better is a simple URL shortener written in Ruby using the
[Sinatra][sinatra] web framework and the [Redis][redis] database.

## Installation

#### Redis

Be sure to have Redis installed first. I personally love DigitalOcean tutorials,
and they made [one dedicated to installing Redis][redis-do-installation].

Otherwise, Redis itself has an [easy-to-go guide][redis-installation-guide].

#### Clone and install dependencies

Clone everything and install dependencies:
``` bash
git clone https://github.com/whatyouhide/short-is-better /path/to/wherever/you/want
cd /path/to/wherever/you/want
bundle install
```

Check that everything works fine:
```
bundle exec rake test
```

Start the server (assuming Redis is running):
```
bundle exec rackup -p [YOUR_PORT]
```

#### Redis connection setup

In order to tweak the Redis connection, set the `$REDIS_URL` environment
variable to something like:

    redis://:p4ssw0rd@10.0.1.1:6380/15

or, in template-language:

    redis://:{password}@{bind}:{port}/{db_id}

If you don't know how to set this variable, you have multiple options:

``` bash
# Using 'export' in the current shell, which ensures this variable is set but
# *only* in this shell (i.e. if you exit or change shell you won't have the
# variable set):
export REDIS_URL='redis://:pass@0.0.0.0:6379/0'

# Using a db for a specific run:
REDIS_URL='redis://:pass@0.0.0.0:6379/0' bundle exec rackup

# Putting the export statement in your ~/.(ba|z)shrc:
echo 'export REDIS_URL="redis://:pass@0.0.0.0:6379/0"' > ~/.bashrc # or ~/.zshrc
```

## License

MIT &copy; 2014 Andrea Leopardi


[redis]: http://redis.io/
[sinatra]: http://www.sinatrarb.com/
[redis-do-installation]: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-redis
[redis-installation-guide]: http://redis.io/topics/quickstart
