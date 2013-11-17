#!/usr/bin/env ruby
require 'inifile'
require 'aws'

if ARGV.length != 1
  if ENV['AWS_KEYSET'] == nil
    abort "Please provid key name as the first argument. You can also set the AWS_KEYSET environment variable."
  else
    keyset = ENV['AWS_KEYSET']
  end
else
  keyset = ARGV[0]
end

file = IniFile.load(File.expand_path('~/.awsconfig'))
data = file['default']
AWS.config(access_key_id: data['aws_access_key_id'], secret_access_key: data['aws_secret_access_key'], region: data['aws_default_region'])
ec2 = AWS.ec2
client = ec2.client

resp = client.describe_instances(filters: [{ name: 'key-name', values: [keyset] }])
resp[:reservation_set].each { |reservation|
  reservation[:instances_set].each { |instance|
    if instance[:instance_state][:code] == 16
      name = instance[:dns_name]
      ip = instance[:ip_address]
      id = instance[:instance_id]
      puts "#{name} #{ip} #{id}"
    end
  }
}
