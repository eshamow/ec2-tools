#!/usr/bin/env ruby
require 'inifile'
require 'aws'
require 'thor'

def LoadConfig(path)
  file = IniFile.load(File.expand_path(path))
  data = file['default']
  AWS.config(access_key_id: data['aws_access_key_id'], secret_access_key: data['aws_secret_access_key'], region: data['aws_default_region'])
  AWS.ec2.client
end

def validate(options,env,command)
  vals = Hash.new()
  if options[:keyset]
    keyset = options[:keyset]
  elsif env['AWS_KEYSET']
    keyset = env['AWS_KEYSET']
  else
    abort "Use --keyset or set AWS_KEYSET variable"
  end
  if options[:configfile]
    configfile = options[:configfile]
  else
    configfile = '~/.awsconfig'
  end

  if command == 'listinstances'
    if options[:state]
      state = options[:state]
    else
      state = 16
    end
    vals[:state] = Integer(state)
  end

  vals[:keyset] = keyset
  vals[:configfile] = configfile

  vals
end

class EC2 < Thor
  class_option :keyset, :type => :string
  class_option :configfile, :type => :string

  desc "listinstances", "List running EC2 instances"
  option :state
  def listinstances
    opts = validate options, ENV, 'listinstances'
    client = LoadConfig opts[:configfile]
    resp = client.describe_instances(filters: [{ name: 'key-name', values: [opts[:keyset]] }])
    resp[:reservation_set].each { |reservation|
      reservation[:instances_set].each { |instance|
        if instance[:instance_state][:code] == opts[:state]
          name = instance[:dns_name]
          ip = instance[:ip_address]
          id = instance[:instance_id]
          int_dns = instance[:private_dns_name]
          puts "#{name} #{ip} #{id} #{int_dns}"
        end
      }
    }
  end

  desc "deleteinstances", "delete EC2 instances"
  option :id
  def deleteinstances
    opts = validate options, ENV, 'deleteinstances'
    client = LoadConfig opts[:configfile]
    begin
      resp = client.terminate_instances({ :instance_ids => [options[:id]] })
    rescue => e
      puts e
    end
  end

  desc "runinstances", "run EC2 instances"
  option :ami
  option :count
  option :groups
  option :keyset
  option :groups
  option :type
  option :ebs
  def runinstances
    opts = validate options, ENV, 'runinstances'
    client = LoadConfig opts[:configfile]
    resp = client.run_instances({
      :image_id => options[:image_id],
      :min_count => options[:count],
      :max_count => options[:count],
      :key_name => options[:keyset],
      :security_groups => options[:groups],
      :instance_type => options[:type],
      :ebs_optimized => options[:ebs],
    })
    if resp[:instance_state][:code] == state
      name = resp[:dns_name]
      ip = resp[:ip_address]
      id = resp[:instance_id]
      int_dns = resp[:private_dns_name]
      puts "#{name} #{ip} #{id} #{int_dns}"
    end
  end
end

EC2.start(ARGV)
