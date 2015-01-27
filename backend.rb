#!/usr/bin/env ruby
# encoding: utf-8

require 'yaml'
require 'grit'
require 'pp'
require 'logger'
require 'time'
require 'timeout'
require 'socket'
require 'mysql2'
require 'active_record'
$ROOT = File.dirname(File.expand_path(__FILE__))
$CONFIG_FILE = File.join $ROOT, "config.yaml"
$TOOLS_CONFIG = File.join $ROOT, "tools.yaml"

$LOAD_PATH.unshift(File.dirname(__FILE__))
require "backend/PingLogger"
require "backend/CompileRepo"


# quick fix to get correct string encoding
YAML::ENGINE.yamler = 'syck'

$CONFIG = Hash.new

LOGGER_VERBOSE = Logger.new STDERR
LOGGER = PingLogger.new STDOUT

def error info
	LOGGER.error info
end

def md5sum fn
	md5 = `md5sum #{fn}`
	fail if $?.exitstatus != 0
	md5
end

###
# Create all the repositories 
###
def create_all_repo
	LOGGER.info "Create or checkout all repos"
	repos = Hash.new
        puts "====#{$CONFIG[:repos]}"
	$CONFIG[:repos].each do |r|
		begin
			repos[ r[:name] ] = CompileRepo.new r
		rescue StandardError => e
			error "#{r[:name]} #{e} not available, skip"
			puts e.backtrace
			next
		end
		
		# Find the result dir
                 puts "======#{repos[ r[:name] ].result_dir}"
		`mkdir -p #{repos[ r[:name] ].result_dir}` unless File.directory? repos[ r[:name] ].result_dir
	end
	repos
end

def startme
	old_config_md5 = nil
	repos = Hash.new
	loop do
		config_md5 = md5sum $CONFIG_FILE
		if config_md5 != old_config_md5
			# Load Config
			puts "============================"
			puts "Loading config..."
			puts "============================"
			$CONFIG = YAML.load File.read($CONFIG_FILE)
			old_config_md5 = config_md5
			
			# Connect to database
			#BugHelper::connectToDB
			ActiveRecord::Base.establish_connection(
:adapter=>"mysql2", :host=>"192.168.0.251",:database=>"thcsos",:username=>"test",:password=>"test");
                      puts "aaaaaaaa"
                       bb=BugHelper::Bug.first.each do |a|
                       puts "#{a.k}=#{a.v}"
                       end
                       exit
			client = Mysql2::Client.new(:host => "192.168.0.251", :username => "test",:password=>"test",:database=>"thcsos")
			results1 = client.query("select * from buglist");
			results1.each do |hash|
  			puts hash.map { |k,v| "#{k} = #{v}" }.join(", ")
			end
			exit
			# Create Repos
			Dir.chdir CompileRepo.source_absdir
			repos = create_all_repo
			
                        puts "#{repos}======"
			# Set Grit limit
			Grit::Git.git_timeout = $CONFIG[:git_timeout] || 10
			Grit::Git.git_max_size = $CONFIG[:git_max_size] || 100000000
        
		end
		
		repos.each do |k,v|
			#chdir first
                        puts v.to_s+"aaaaaaaaaaaaa"
			Dir.chdir File.join(CompileRepo.source_absdir, k)
                        puts "#{$CONFIG[:sleep] || 30}=======1"
			v.start_test
                        puts "#{$CONFIG[:sleep]}=======2"
			Dir.chdir CompileRepo.source_absdir
		end
		
                puts "#{$CONFIG[:sleep]}=======3"
		sleep ($CONFIG[:sleep] || 30)
	end
end

if __FILE__ == $0
	startme
end

