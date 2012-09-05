module Peacekeeper
  class Loader
    attr_reader :source, :config

    def initialize(config)
      @config = config
      @source = config[:source]
    end

    def load_source
      case source
      when :sequel
        require 'sequel'
        Sequel::Model.db = Sequel::DATABASES.find { |db| db.uri == sequel_db_uri } || Sequel.connect(sequel_db_uri)
      when :active_record
        require 'active_record'
        ActiveRecord::Base.establish_connection(active_record_config)
      when :api
        require 'nasreddin'
      when :mock
        require config[:mock_library] if config[:mock_library]
        #data_class # Trigger mock data_class creation
      end
    end

    def load_data_source
      if source.nil?
        nil
      elsif source == :mock
        Kernel.const_set(config['data_name'], Class.new do
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
        require "data/#{source}/#{config['data_lib_name']}"
        Kernel.const_get(config['data_name'])
      end
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
=begin
    def data_lib_name
      name = config['data_name']
      name.gsub!(/::/, '/')
      name.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
      name.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      name.tr!("-", "_")
      name.downcase!
      name
    end
=end
  end
end
