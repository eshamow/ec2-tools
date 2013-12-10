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

def validate(options,env)
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

  {
    :keyset => keyset,
    :configfile => configfile
  }
end

class EC2 < Thor
  class_option :keyset, :type => :string
  class_option :configfile, :type => :string

  desc "listinstances", "List running EC2 instances"
  option :state
  def listinstances
    if options[:state]
      state = options[:state].to_i
    else
      state = 16
    end

    opts = validate options, ENV
    client = LoadConfig opts[:configfile]
    resp = client.describe_instances(filters: [{ name: 'key-name', values: [opts[:keyset]] }])
    resp[:reservation_set].each { |reservation|
      reservation[:instances_set].each { |instance|
        if instance[:instance_state][:code] == state
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
    opts = validate options, ENV
    client = LoadConfig opts[:configfile]
    validate options, ENV
    begin
      resp = client.terminate_instances({ :instance_ids => [options[:id]] })
    rescue => e
      puts e
    end
  end
end

EC2.start(ARGV)
