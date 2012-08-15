module Peacekeeper
  module ModelDelegation
    class Pass
      def self.===(o)
        false
      end
    end

    def method_missing(mid, *args, &block)
      if !delegate.nil? && delegate.respond_to?(mid)
        mblock = begin
                   delegate.method(mid).to_proc
                 rescue NameError
                   proc do |*args, &block|
                     delegate.send(mid, *args, &block)
                   end
                 end
        define_wrapped_singleton_method(mid, mblock)
        __send__(mid, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(mid, include_private)
      ret = delegate.respond_to?(mid, include_private)
      if ret && include_private && !delegate.respond_to?(mid, false)
        # Don't delegate private methods
        return false
      end
      ret
    end

    def wrap(val)
      if (self.kind_of?(Class) && val.kind_of?(delegate))
        new(val)
      elsif (self.kind_of?(Peacekeeper::Model) && val.kind_of?(delegate.class))
        self.class.new(val)
      elsif (Peacekeeper::Model.has_wrapper_for?(val.class))
        Peacekeeper::Model.wrapper_for(val.class).new(val)
      elsif (val.kind_of?(Hash))
        Hash[*val.flat_map { |k, v| [k, wrap(v)] }]
      elsif (val.kind_of?(Enumerable) || val.methods.include?(:each))
        val.map { |i| wrap(i) }
      else
        val
      end
    end

    def define_wrapped_singleton_method(mid, mblock)
      define_singleton_method(mid) do |*args, &block|
        wrap(mblock.call(*args, &block))
      end
    end

    def def_data_method(mid, &mblock)
      define_method(mid) do |*args|
        wrap(delegate.instance_exec(*args, &mblock))
      end
    end

    def def_singleton_data_method(mid, &mblock)
      define_singleton_method(mid) do |*args|
        wrap(delegate.instance_exec(*args, &mblock))
      end
    end
  end

  class Model
    kernel = ::Kernel.dup
    kernel.class_eval do
      [:to_s, :inspect, :=~, :!~, :===, :<=>, :eql?, :hash].each do |m|
        undef_method m
      end
    end
    include kernel

    class<<self
      include ModelDelegation

      def new(*)
        raise RuntimeError, "ModelObject cannot be instantiated directly. Please subclass first!" if self == Model
        super
      end

      def subclasses; (@subclasses ||= []); end

      def config; (@config ||= {}); end
      def connection; (@connection ||= nil); end

      def config=(new_config)
        @config = new_config
        subclasses.each do |sub|
          sub.config = @config
        end
      end

      def data_source; (@data_source ||= nil); end
      alias :orm :data_source # orm is depricated

      def data_source=(source)
        @data_source = source
        @data_class = nil
        case source
        when :sequel
          require 'sequel'
          Sequel::Model.db = Sequel::DATABASES.find { |db| db.uri == sequel_db_uri } || Sequel.connect(sequel_db_uri)
        when :active_record
          require 'active_record'
          ActiveRecord::Base.establish_connection(active_record_config)
          @connection = ActiveRecord::Base.connection()
        when :api
          require 'nasreddin'
        when :mock
          require config[:mock_library] if config[:mock_library]
          data_class # Trigger mock data_class creation
        end

        subclasses.each do |sub|
          sub.data_source = @data_source
        end

        @data_source
      end
      alias :orm= :data_source= # orm= is depricated

      def data_class
        return nil if self == Model
        @data_class ||= begin
          if data_source.nil?
            nil
          elsif data_source == :mock
            Kernel.const_set(data_name, Class.new do
                                          def self.new(opts = {})
                                            mock(self.name.gsub(/^.*:/, ''), opts)
                                          end
                                          def self.method_missing(*)
                                            self.new
                                          end
                                          def self.respond_to?(*)
                                            true
                                          end
                                        end)
          else
            require "data/#{data_source}/#{data_lib_name}"
            Kernel.const_get(data_name)
          end
        end
      end
      alias :delegate :data_class

      def inherited(sub)
        unless sub.name.nil?
          subclasses << sub
          sub.setup(self)
        end
      end

      def has_wrapper_for?(val)
        !!wrapper_for(val)
      end

      def wrapper_for(val)
        subclasses.find do |subclass|
          val == subclass.delegate
        end
      end

      def setup(parent)
        self.config = parent.config
        self.data_source = parent.data_source
      end

      # Construct uri to connect to database
      # Sequel: http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html
      def sequel_db_uri
        # Set the protocol (DB engine; i.e. mysql, sqlite3, postgres, etc.)
        protocol = config['protocol'] || config['adapter'] || 'sqlite'
        if RUBY_ENGINE == 'jruby'
          protocol = "jdbc:#{protocol}" unless protocol.start_with? "jdbc:"
        end

        # Set the path (hostname & database name)
        path = "#{config['host'] || config['path']}/#{config['database']}"
        path = '' if path == '/' # Clear path if 'host', 'path', and 'database' are all unset

        # Set the user and password
        if RUBY_ENGINE == 'jruby' && protocol == 'jdbc:mysql'
          # Special case for JRuby and MySQL
          user_pass = "?user=#{config['username']}&password=#{config['password']}"
          server_path = "#{path}#{user_pass}"
        else
          user_pass = "#{config['username']}:#{config['password']}@"
          user_pass = '' if user_pass == ':@' # Clear user_pass if both 'username' and 'password' are unset
          server_path = "#{user_pass}#{path}"
        end

        # Finally, put the protocol and path components together
        server_path = "/#{server_path}" unless server_path.empty?
        uri = "#{protocol}:/#{server_path}"
        uri = 'jdbc:sqlite::memory:' if uri == 'jdbc:sqlite:/' && RUBY_ENGINE == 'jruby'
        if config['options']
          if uri =~ /\?/
            uri += "&#{paramize(config['options'])}"
          else
            uri += "?#{paramize(config['options'])}"
          end
        end
        uri
      end

      def active_record_config
        protocol = config['protocol'] || config['adapter'] || 'sqlite3'
        # Set the adapter (DB engine; i.e. mysql, sqlite3, postgres, etc.)

        database = config['database']
        ar_config = {
          adapter:  protocol,
          database: database
        }
        ar_config['host'] = config['host'] if config['host']
        ar_config['username'] = config['username'] if config['username']
        ar_config['password'] = config['password'] if config['password']
        ar_config['driver'] = config['driver'] if config['driver']
        ar_config
      end

      def paramize(options)
        params = options.map { |k, v| "#{k}=#{v}" }
        "#{params.join('&')}"
      end

      def data_name
        self.name.sub(/Model$/, '')
      end

      def data_lib_name
        name = data_name
        name.gsub!(/::/, '/')
        name.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
        name.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
        name.tr!("-", "_")
        name.downcase!
        name
      end
    end

    include ModelDelegation

    attr_reader :data
    alias :delegate :data

    def initialize(*args)
      if !args.nil? && args.length == 1 && args.first.kind_of?(data_class)
        @data = args.first
      else
        @data = data_class.new(*args)
      end

      class<<self
         puts "undefining :to_json"
         undef :to_json if respond_to?(:to_json)
      end
    end

    def ==(obj)
      obj.equal?(self) || @data == obj.data
    end

    def data_class
      self.class.data_class
    end
  end
end
