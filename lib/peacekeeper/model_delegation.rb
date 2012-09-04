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
end