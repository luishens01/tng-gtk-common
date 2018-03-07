## Copyright (c) 2015 SONATA-NFV, 2017 5GTANGO [, ANY ADDITIONAL AFFILIATION]
## ALL RIGHTS RESERVED.
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
## Neither the name of the SONATA-NFV, 5GTANGO [, ANY ADDITIONAL AFFILIATION]
## nor the names of its contributors may be used to endorse or promote
## products derived from this software without specific prior written
## permission.
##
## This work has been performed in the framework of the SONATA project,
## funded by the European Commission under Grant number 671517 through
## the Horizon 2020 and 5G-PPP programmes. The authors would like to
## acknowledge the contributions of their colleagues of the SONATA
## partner consortium (www.sonata-nfv.eu).
##
## This work has been performed in the framework of the 5GTANGO project,
## funded by the European Commission under Grant number 761493 through
## the Horizon 2020 and 5G-PPP programmes. The authors would like to
## acknowledge the contributions of their colleagues of the 5GTANGO
## partner consortium (www.5gtango.eu).
# encoding: utf-8
require_relative '../spec_helper'

RSpec.describe UploadPackageService do
  include Rack::Test::Methods
  let(:user_callback_url)  {'http://example.com/user'}
  describe '.call' do
    let (:result) {{ package_process_uuid: "03921bbe-8d9f-4cfc-b6ab-88b58cb8db7e"}}
    let(:unpackager_url) {'http://example.com/unpackager'}
    let(:internal_callback_url)  {'http://example.com/internal'}
    let(:content_type) {'multipart/form-data'}
    let(:file_data) { Rack::Test::UploadedFile.new(__FILE__, content_type)}
    let(:params) { {'callback_url'=> user_callback_url, 'layer'=> 'xyz', 'format'=>''}.merge!({
      "package"=>{
        filename: __FILE__, 
        type: nil, 
        name: "package", 
        tempfile: file_data,
        head: "Content-Disposition: form-data; name=\"package\"; filename=\"Gemfile\"\r\n"
    }})}
    
    it 'calls the unpackager' do
      stub_request(:post, "http://example.com/unpackager").
        #with(body: "package=%2Ftmp%2FUIYUYTZT20180306-49778-fcognf&callback_url=http%3A%2F%2Fexample.com%2Finternal&layer=xyz&format=").
        to_return(status: 200, body: result.to_json, headers: {})
      code, body = UploadPackageService.call(params, content_type, unpackager_url, internal_callback_url)
      expect(code).to eq(200)
      expect(body).to eq(result)
    end
  end
  describe '.process_callback' do
    let(:params) { {event_name: "evt", package_id: "123", package_location: "xyz", package_process_uuid: "abc"}}
    let(:external_callback_url) { 'http://example.com/external'}
    before(:each) {
      WebMock.stub_request(:post, external_callback_url).
        with(body: params.to_json, headers: {'Accept'=>'application/json', 'Content-Type'=>'application/json'}).
        to_return(status: 200, body: "", headers: {})
      WebMock.stub_request(:post, user_callback_url).
        with(body: params.to_json, headers: {'Accept'=>'application/json', 'Content-Type'=>'application/json'}).
        to_return(status: 200, body: "", headers: {})
    }
    it 'calls the external callback' do
      UploadPackageService.class_variable_set :@@internal_callbacks, {'abc'.to_sym => user_callback_url}
      expect{UploadPackageService.process_callback(params, external_callback_url)}.not_to raise_error
    end
    it 'calls the user callback (if exists)' do
      UploadPackageService.class_variable_set :@@internal_callbacks, {'abc'.to_sym => user_callback_url}
      expect{UploadPackageService.process_callback(params, external_callback_url)}.not_to raise_error
    end
    it 'does not call the user callback when it does not exist' do
      UploadPackageService.class_variable_set :@@internal_callbacks, {'abc'.to_sym => nil}
      expect{UploadPackageService.process_callback(params, external_callback_url)}.not_to raise_error
    end
    
    #resp = OpenStruct.new(header_str: "HTTP/1.1 200 OK\nRecord-Count: 1", body: token.to_json)            
    #allow(Curl).to receive(:post).with(login_url, '{}').and_return(resp)
    
  end
end