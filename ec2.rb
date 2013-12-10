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

class EC2 < Thor
  class_option :keyset, :type => :string

  desc "listinstances", "List running EC2 instances"
  option :configfile
  def listinstances
    if options[:keyset]
      keyset = options[:keyset]
    elsif ENV['AWS_KEYSET']
      keyset = ENV['AWS_KEYSET']
    else
      abort "Use --keyset or set AWS_KEYSET variable"
    end
    if options[:configfile]
      configfile = options[:configfile]
    else
      configfile = '~/.awsconfig'
    end

    client = LoadConfig configfile
    resp = client.describe_instances(filters: [{ name: 'key-name', values: [keyset] }])
    resp[:reservation_set].each { |reservation|
      reservation[:instances_set].each { |instance|
        if instance[:instance_state][:code] == 16
          name = instance[:dns_name]
          ip = instance[:ip_address]
          id = instance[:instance_id]
          int_dns = instance[:private_dns_name]
          puts "#{name} #{ip} #{id} #{int_dns}"
        end
      }
    }
  end
end

EC2.start(ARGV)
