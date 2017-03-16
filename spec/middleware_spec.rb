describe 'rack middleware' do
  it 'assembles production middleware' do
    # this can catch errors in production middleware configuration
    expect(
      system(
        'rake middleware ' \
        'RAILS_ENV=production ' \
        'RAILS_SERVE_STATIC_FILES=true ' \
        '> /dev/null 2>&1'
      )
    ).to eq(true)
  end
end
