require 'json'
require 'pathname'
require 'pp'
require 'ap'

require 'aws-sdk-cloudformation'
require 'aws-sdk-cognitoidentityprovider'

ROOT_DIR        = Pathname.new '/app'
STACK_NAME      = ENV.fetch 'STACK_NAME'
TEMPLATE_FILE   = ROOT_DIR.join 'template.yml'
ENV_FILE        = '/tmp/env.json'.freeze

LAMBDA_REGEX    = /^lambda--(.*)--env--(.*)$/

def stack_describe1
  JSON.parse `aws cloudformation describe-stacks --stack-name=#{STACK_NAME}`
end

def stack_describe
  client = Aws::CloudFormation::Client.new
  resp = client.describe_stacks stack_name: STACK_NAME

  outputs = resp.stacks.first.outputs
  ret = outputs.map do |o|
    {
      'OutputKey'   => o.output_key,
      'OutputValue' => o.output_value,
      'Description' => o.description
    }
  end

  ret
end

def lambda_envs
  lambda_output = stack_describe.select do |e|
    description = e['Description'].to_s
    description.match LAMBDA_REGEX
  end

  envs = {}
  lambda_output.each do |e|
    description = e['Description']
    m = description.match LAMBDA_REGEX

    func_name = m[1]
    env_name  = m[2]
    value     = e['OutputValue']

    envs[func_name] = {} if envs[func_name].nil?
    envs[func_name][env_name] = value
  end
  envs
end
