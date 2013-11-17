#!/usr/bin/env ruby
require 'inifile'
require 'aws'

file = IniFile.load(File.expand_path('~/.awsconfig'))
data = file['default']
AWS.config(access_key_id: data['aws_access_key_id'], secret_access_key: data['aws_secret_access_key'], region: data['aws_default_region'])
ec2 = AWS.ec2
client = ec2.client

begin
  resp = client.terminate_instances({ :instance_ids => ARGV })
rescue => e
  puts e
end
