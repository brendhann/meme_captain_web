require 'rails_helper'

describe 'response compression', type: :request do
  it 'compresses html' do
    get(
      '/',
      params: {},
      headers: { 'Accept-Encoding' => 'gzip, deflate, sdch' }
    )
    expect(response.headers['Content-Encoding']).to eq('gzip')
  end

  it 'compresses css' do
    get(
      '/assets/application.self.css',
      params: {},
      headers: { 'Accept-Encoding' => 'gzip, deflate, sdch' }
    )
    expect(response.headers['Content-Encoding']).to eq('gzip')
  end

  it 'compresses javascript' do
    get(
      '/assets/application.self.js',
      params: {},
      headers: { 'Accept-Encoding' => 'gzip, deflate, sdch' }
    )
    expect(response.headers['Content-Encoding']).to eq('gzip')
  end

  it 'does not compress images' do
    image = FactoryGirl.create(:gend_image, work_in_progress: false)
    get(
      "/gend_images/#{image.id_hash}.#{image.format}",
      params: {},
      headers: { 'Accept-Encoding' => 'gzip, deflate, sdch' }
    )
    expect(response.headers['Content-Encoding']).to be_nil
  end
end
