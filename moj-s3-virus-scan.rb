require 'aws-sdk-s3'
require 'puma'
require 'pry'
require 'sinatra'
require 'yaml'

configure do
  set :bind, '0.0.0.0'
  set :server, :puma
  set :clamscan_executable, ENV.fetch('CLAMSCAN_EXECUTABLE', 'clamscan')
end

Aws.config.update region: 'eu-west-1'

get '/ping' do
  'OK'
end

def s3_client_for_bucket(bucket_name)
  bucket_credentials_file = "secrets/buckets/#{bucket_name}.yml"
  if File.exist?(bucket_credentials_file)
    credentials = YAML.load_file(bucket_credentials_file)

    Aws::S3::Client.new(
      credentials: Aws::Credentials.new(credentials['aws_access_key_id'],
                                        credentials['aws_secret_access_key']),
      region: 'eu-west-1'
    )
  else
    # Use the default credentials which should be read from ~/.aws
    Aws::S3::Client.new
  end
end

def get_s3_object(client, bucket_name, key)
  extname = File.extname(key)
  tmpfile = Tempfile.new(['object', extname])
  object = Aws::S3::Object.new(bucket_name, key, client: client)
  tmpfile.write(object.data)
  tmpfile.close
  File.chmod(0o644, tmpfile.path)
  [tmpfile.path, object]
end

get '/scan' do
  bucket_name = params['bucket']
  key         = params['key']

  client = s3_client_for_bucket(bucket_name)
  begin
    (local_path, object) = get_s3_object(client, bucket_name, key)

    cmd = [settings.clamscan_executable, local_path]
    warn "Scanning for viruses: #{cmd.join(' ')}"
    if system(*cmd)
      warn "CLEAN #{bucket_name}/#{key}"
      object.put(tagging: 'moj-virus-scan=CLEAN')
      '{"result": "CLEAN"}'
    else
      warn "INFECTED #{bucket_name}/#{key}"
      object.put(tagging: 'moj-virus-scan=INFECTED')
      '{"result": "INFECTED"}'
    end
  ensure
    File.unlink(local_path)
  end
end
