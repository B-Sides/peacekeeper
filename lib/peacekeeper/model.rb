module Peacekeeper
  module ModelDelegation
    class Pass
      def self.===(o)
        false
      end
    end

    def method_missing(mid, *args, &block)
      if !delegate.nil? && delegate.respond_to?(mid)
        define_wrapped_singleton_method(mid, delegate.method(mid).to_proc)
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
      case val
        when Hash
          Hash[*val.flat_map { |k, v| [k, wrap(v)] }]
        when Enumerable
          val.map { |i| wrap(i) }
        when (self.kind_of?(Class) ? delegate : Pass)
          new(val)
        when delegate.class
          self.class.new(val)
        when *(data_classes = Model.subclasses.each_with_object({}) { |e, h| h[e.data_class] = e }).keys
          data_classes[val.class].new(val)
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

      def subclasses;
        (@subclasses ||= []);
      end

      def config;
        (@config ||= {});
      end

      def config=(new_config)
        @config = new_config
        subclasses.each do |sub|
          sub.config = @config
        end
      end

      def orm;
        (@orm ||= nil);
      end

      def orm=(orm_lib)
        case orm_lib
          when :sequel
            @orm = orm_lib
            require 'sequel'
            Sequel::Model.db = Sequel::DATABASES.find { |db| db.uri == sequel_db_uri } || Sequel.connect(sequel_db_uri)
        end
        subclasses.each do |sub|
          sub.orm = @orm
        end
      end

      def data_class
        return nil if self == Model
        @data_class ||= begin
          if orm.nil?
            nil
          else
            require "data/#{orm}/#{data_lib_name}"
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

      def setup(parent)
        self.config = parent.config
        self.orm = parent.orm
      end

      # Construct uri to connect to database  
      # Sequel: http://sequel.rubyforge.org/rdoc/files/doc/opening_databases_rdoc.html
      def sequel_db_uri
        if config['adapter'] == 'jdbc:mysql'
          "#{config['adapter']}://#{config['host']}/#{config['database']}?user=#{config['username']}&password=#{config['password']}"
        else
          protocol = config['protocol'] || config['adapter'] || 'sqlite'
          user_pass = "#{config['username']}:#{config['password']}@"
          user_pass = '' if user_pass == ':@' # Clear user_pass if both 'username' and 'password' are unset
          path = "#{config['host'] || config['path']}/#{config['database']}"
          path = '' if path == '/' # Clear path if 'host', 'path', and 'database' are all unset
          server_path = "#{user_pass}#{path}"
          server_path = "/#{server_path}" unless server_path.empty?
          "#{protocol}:/#{server_path}"
        end
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
    end

    def ==(obj)
      obj.equal?(self) || @data == obj.data
    end

    def data_class
      self.class.data_class
    end
  end
end
