require 'sinatra'
require 'pry'
require 'aws-sdk-s3'
require 'puma'

configure do
  set :bind, '0.0.0.0'
  set :server, :puma
end


Aws.config.update region: 'eu-west-1'

get '/ping' do
  'OK'
end

get '/scan' do
  bucket_name = params['bucket']
  bucket = Aws::S3::Resource.new.bucket(bucket_name)
  key = params['key']
  object = bucket.object(key)

  extname = File.extname(key)
  tmpfile = Tempfile.new(['object', extname])
  tmpfile.close
  object.get(response_target: tmpfile.path)
  File.chmod(0o644, tmpfile.path)
  cmd = ['clamdscan', tmpfile.path]
  warn "Scanning for viruses: #{cmd.join(' ')}"
  if system(*cmd)
    object.put(tagging: 'moj-virus-scan=CLEAN')
    warn "NO virus found for: #{tmpfile.path}"
    '{"result": "CLEAN"}'
  else
    object.put(tagging: 'moj-virus-scan=INFECTED')
    warn "virus FOUND for: #{tmpfile.path}"
    '{"result": "INFECTED"}'
  end
ensure
  tmpfile.unlink
end
