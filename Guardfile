# Guardfile for orm_sampler
# More info at https://github.com/guard/guard#readme

# parameters:
#  output     => the formatted to use
#  backtrace  => number of lines, nil =  everything
guard 'bacon', :output => "BetterOutput", :backtrace => 4 do
  watch(%r{^lib/(.+)\.rb$})     { |m| "test/#{m[1]}_test.rb" }
  watch(%r{^test/test_helper\.rb$}) { |m| Dir['spec/**/*_test.rb'] }
  watch(%r{^test/(?!fixtures/)(?!tmp/).+\.rb$})
end

