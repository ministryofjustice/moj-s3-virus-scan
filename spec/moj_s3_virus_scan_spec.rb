describe 'MOJ S3 Virus Scan app' do
  describe 'ping' do
    it 'responds with OK' do
      get '/ping'

      expect(last_response.body).to eq 'OK'
    end
  end

  describe '/scan' do
    let(:credentials) { instance_double(Aws::Credentials) }
    let(:client)      { instance_double(Aws::S3::Client) }
    let(:object)      { instance_double(Aws::S3::Object,
                                        data: 'I AM NOT INFECTED!!!',
                                        put: nil) }
    let(:virus_found?) { false }

    before do
      allow(Aws::Credentials).to receive(:new).and_return(credentials)
      allow(Aws::S3::Client).to receive(:new).and_return(client)
      allow(Aws::S3::Object).to receive(:new).and_return(object)

      allow_any_instance_of(app).to receive(:warn)
      allow_any_instance_of(app).to receive(:system).and_return(!virus_found?)
    end

    context 'file contains no viruses' do
      it 'uses credentials from the buckets secret' do
        FakeFS do
          # Useful for debugging, e.g. pry will try to load this file.
          FakeFS::FileSystem.clone('moj-s3-virus-scan.rb')

          # Make sure we can download the S3 object to our local tmpdir
          FileUtils.mkdir_p(Dir.tmpdir)

          # Here's the important bit ... create our fake secrets.
          secret_buckets_dir = File.join(app.root, 'secrets/buckets')
          FileUtils.mkdir_p(secret_buckets_dir)
          File.write(File.join(secret_buckets_dir, 'test-bucket.yml'),
                     {'aws_access_key_id'    => 'test-access-id',
                      'aws_secret_access_key' => 'test-secret-key'}.to_yaml)

          get '/scan?bucket=test-bucket&key=some/test/file.pdf'

          expect(Aws::Credentials).to have_received(:new)
                                        .with('test-access-id', 'test-secret-key')
          expect(Aws::S3::Client).to have_received(:new)
                                       .with(credentials: credentials,
                                             region: 'eu-west-1')
        end
      end

      it 'retrieves the correct object from S3' do
        get '/scan?bucket=test-bucket&key=some/test/file.pdf'

        expect(Aws::S3::Object).to have_received(:new)
                                     .with('test-bucket',
                                           'some/test/file.pdf',
                                           client: client)
      end

      describe 'the downloaded temporary file' do
        let(:tempfile) { instance_double(Tempfile,
                                         path: '/tmp/object.pdf',
                                         write: 0,
                                         close: nil,
                                         chmod: nil) }
        before do
          allow(Tempfile).to receive(:new).and_return(tempfile)
        end

        it 'chmods the file' do
          get '/scan?bucket=test-bucket&key=some/test/file.pdf'

          expect(tempfile).to have_received(:chmod).with(0o644)
        end

        it 'writes the object data to the file' do
          get '/scan?bucket=test-bucket&key=some/test/file.pdf'

          expect(tempfile).to have_received(:write).with('I AM NOT INFECTED!!!')
        end

        it 'scans the file with ClamAV' do
          expect_any_instance_of(app).to receive(:system).with('clamscan', tempfile.path)

          get '/scan?bucket=test-bucket&key=some/test/file.pdf'
        end

      end

      it 'updates the object tags in S3' do
        get '/scan?bucket=test-bucket&key=some/test/file.pdf'

        expect(object).to have_received(:put)
                            .with(tagging: 'moj-virus-scan=CLEAN')
      end

      it 'removes the downloaded file' do
        allow(File).to receive(:unlink)
      end
    end

    context 'file contains a virus' do
      let(:virus_found?) { true }

      it 'tags the object as infected in S3' do
        get '/scan?bucket=test-bucket&key=some/test/file.pdf'

        expect(object).to have_received(:put)
                            .with(tagging: 'moj-virus-scan=INFECTED')
      end
    end

    context 'clamscan_executable setting is changed' do
      before do
        @clamscan_executable = app.settings.clamscan_executable
        app.settings.set :clamscan_executable, 'clamdscan'
      end

      after do
        app.settings.set :clamscan_executable, @clamscan_executable
      end

      it 'uses the value of the new setting' do
        expect_any_instance_of(app).to receive(:system).with('clamdscan', anything)

        get '/scan?bucket=test-bucket&key=some/test/file.pdf'
      end
    end

    context 'no buckets secret' do
      it 'uses default credentials' do
        get '/scan?bucket=test-bucket&key=some/test/file.pdf'

        expect(Aws::S3::Client).to have_received(:new).with(no_args)
      end
    end

    context 'S3 object does not exist' do
      it 'returns an error status' do
        allow(object).to receive(:data).and_raise(Exception)

        get '/scan?bucket=test-bucket&key=some/test/file.pdf'

        expect(last_response.status).to eq 500
      end
    end
  end
end

