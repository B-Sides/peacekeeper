$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('../fixtures', __FILE__)

require 'ruby-debug'
begin
  require 'pry'
rescue LoadError
  $stderr.puts 'Install the pry gem for better debugging.'
end
require 'facon'
require 'peacekeeper'

# Until JRuby fixes http://jira.codehaus.org/browse/JRUBY-6550 ...
class Should
  def satisfy(*args, &block)
    if args.size == 1 && String === args.first
      description = args.shift
    else
      description = ""
    end

    # ToDo Jruby bug not yet resolved see http://jira.codehaus.org/browse/JRUBY-6550 Victor Christensen at 2:06 PM on 4/20/12
    #r = yield(@object, *args)
    r = yield(@object)
    if Bacon::Counter[:depth] > 0
      Bacon::Counter[:requirements] += 1
      raise Bacon::Error.new(:failed, description) unless @negated ^ r
    else
      @negated ? !r : !!r
    end
  end
end

###
#
# This is a dirty, dirty trick to write tests that test `require`:
# TODO: Need to create a Loader class to properly fix this.
#
module RequireMock
  REQUIRE_SENTINEL = []

  def require(lib)
    REQUIRE_SENTINEL << lib
    super
  end
end
Object.send(:include, RequireMock)

def require_lib(lib)
  ->(block) do
    REQUIRE_SENTINEL.clear
    block.call
    REQUIRE_SENTINEL.include?(lib)
  end
end

#
###

