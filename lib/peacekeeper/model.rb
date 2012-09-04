module Peacekeeper
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

      def config=(new_config)
        @config = new_config
        @config['data_name'] = data_name
        @config['data_lib_name'] = data_lib_name
        @loader = Loader.new(@config)

        subclasses.each do |sub|
          sub.config = @config
        end
      end

      def data_source; (@data_source ||= nil); end

      def data_source=(source)
        @data_source = source
        @loader.source = source
        @loader.load_source

        if source == :mock
          data_class # Trigger mock data_class creation
        end

        subclasses.each do |sub|
          sub.data_source = @data_source
        end

        @data_source
      end

      def data_class
        return nil if self == Model
        #@data_class ||= (@loader.nil? ? nil : @loader.load_data_source)
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

      unless self.class.instance_methods(false).include?(:to_json)
        class<<self
          undef_method :to_json if respond_to?(:to_json)
        end
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
