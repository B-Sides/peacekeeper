require 'benchmark'
require 'set'

class Pre
  def initialize(target)
    (target.methods - methods).each do |m|
      define_singleton_method(m, target.method(m).to_proc)
    end
  end
end

class Post
  def initialize(target)
    @target = target
  end

  def method_missing(mid, *args, &block)
    t = @target
    define_singleton_method(mid, t.method(mid).to_proc)
    __send__(mid, *args, &block)
  end
end

class OnDemand
  def initialize(target)
    @target = target
  end

  def method_missing(mid, *args, &block)
    @target.__send__(mid, *args, &block)
  end
end

class Reversible
  def initialize(target)
    @delegated = Set.new
    @target = target
  end

  def method_missing(mid, *args, &block)
    @delegated << mid
    t = @target
    define_singleton_method(mid, t.method(mid).to_proc)
    __send__(mid, *args, &block)
  end

  def reset
    class<<self
      undef_method *@delegated
    end
    @delegated.clear
  end
end

puts "\nCall one method"
Benchmark.bm(14) do |x|
  x.report('Pre-delegate') { 10000.times { p = Pre.new('test'); p.length } }
  x.report('Post-delegate') { 10000.times { p = Post.new('test'); p.length } }
  x.report('On Demand') { 10000.times { p = OnDemand.new('test'); p.length } }
  x.report('Reversible') { 10000.times { p = Reversible.new('test'); p.length; p.reset } }
end

puts "\nCall one method 100 times"
Benchmark.bm(14) do |x|
  x.report('Pre-delegate') { 10000.times { p = Pre.new('test'); 100.times { p.length } } }
  x.report('Post-delegate') { 10000.times { p = Post.new('test'); 100.times { p.length } } }
  x.report('On Demand') { 10000.times { p = OnDemand.new('test'); 100.times { p.length } } }
  x.report('Reversible') { 10000.times { p = Reversible.new('test'); 100.times { p.length }; p.reset } }
end

puts "\nCall one method 10,000 times"
Benchmark.bm(14) do |x|
  x.report('Pre-delegate') { 10000.times { p = Pre.new('test'); 10000.times { p.length } } }
  x.report('Post-delegate') { 10000.times { p = Post.new('test'); 10000.times { p.length } } }
  x.report('On Demand') { 10000.times { p = OnDemand.new('test'); 10000.times { p.length } } }
  x.report('Reversible') { 10000.times { p = Reversible.new('test'); 10000.times { p.length }; p.reset } }
end

puts "\nCall three methods"
Benchmark.bm(14) do |x|
  x.report('Pre-delegate') { 10000.times { p = Pre.new('test'); p.length; p.reverse; p.upcase } }
  x.report('Post-delegate') { 10000.times { p = Post.new('test'); p.length; p.reverse; p.upcase } }
  x.report('On Demand') { 10000.times { p = OnDemand.new('test'); p.length; p.reverse; p.upcase } }
  x.report('Reversible') { 10000.times { p = Reversible.new('test'); p.length; p.reverse; p.upcase; p.reset } }
end

puts "\nCall three methods 100 times"
Benchmark.bm(14) do |x|
  x.report('Pre-delegate') { 10000.times { p = Pre.new('test'); 100.times { p.length; p.reverse; p.upcase } } }
  x.report('Post-delegate') { 10000.times { p = Post.new('test'); 100.times { p.length; p.reverse; p.upcase } } }
  x.report('On Demand') { 10000.times { p = OnDemand.new('test'); 100.times { p.length; p.reverse; p.upcase } } }
  x.report('Reversible') { 10000.times { p = Reversible.new('test'); 100.times { p.length; p.reverse; p.upcase }; p.reset } }
end

puts "\nCall three methods 10,000 times"
Benchmark.bm(14) do |x|
  x.report('Pre-delegate') { 10000.times { p = Pre.new('test'); 10000.times { p.length; p.reverse; p.upcase } } }
  x.report('Post-delegate') { 10000.times { p = Post.new('test'); 10000.times { p.length; p.reverse; p.upcase } } }
  x.report('On Demand') { 10000.times { p = OnDemand.new('test'); 10000.times { p.length; p.reverse; p.upcase } } }
  x.report('Reversible') { 10000.times { p = Reversible.new('test'); 10000.times { p.length; p.reverse; p.upcase }; p.reset } }
end
