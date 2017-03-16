require 'rails_helper'

require 'support/src_image_skip_callbacks'
require 'support/stop_time'

describe SrcImagesController, type: :controller do
  include StatsD::Instrument::Matchers

  let(:user) { FactoryGirl.create(:user) }
  let(:user2) { FactoryGirl.create(:user, email: 'user2@user2.com') }

  before(:each) do
    session[:user_id] = user.try(:id)
  end

  describe "GET 'new'" do
    context 'when the user is logged in' do
      it 'returns http success' do
        get :new
        expect(response).to be_success
      end
    end

    context 'when the user it not logged in' do
      let(:user) { nil }
      it 'redirects to the login form' do
        get :new
        expect(response).to redirect_to new_session_path
      end
    end
  end

  describe "GET 'index'" do
    it 'returns http success' do
      get(:index)

      expect(response).to be_success
    end

    it 'shows the images sorted by reverse gend image count' do
      si1 = FactoryGirl.create(:src_image,
                               user: user,
                               gend_images_count: 20,
                               work_in_progress: false)
      si2 = FactoryGirl.create(:src_image,
                               user: user,
                               gend_images_count: 10,
                               work_in_progress: false)
      si3 = FactoryGirl.create(:src_image,
                               user: user,
                               gend_images_count: 30,
                               work_in_progress: false)

      get(:index)

      expect(assigns(:src_images)).to eq([si3, si1, si2])
    end

    context 'when the user is not an admin user' do
      it 'does not show deleted images' do
        FactoryGirl.create(:src_image, user: user, work_in_progress: false)
        FactoryGirl.create(
          :src_image, user: user, is_deleted: true, work_in_progress: false
        )

        get(:index)

        expect(assigns(:src_images).size).to eq(1)
      end

      it 'does not show work in progress images' do
        FactoryGirl.create(:src_image, user: user)
        FactoryGirl.create(:src_image, user: user, work_in_progress: false)

        get(:index)

        expect(assigns(:src_images).size).to eq(1)
      end

      it 'shows public images' do
        FactoryGirl.create(:src_image, private: true, work_in_progress: false)
        3.times { FactoryGirl.create(:src_image, work_in_progress: false) }

        get(:index)

        expect(assigns(:src_images).size).to eq(3)
      end
    end

    context 'when the user is an admin user' do
      let(:user) { FactoryGirl.create(:admin_user) }

      it 'shows deleted images' do
        FactoryGirl.create(:src_image, user: user, work_in_progress: false)
        FactoryGirl.create(
          :src_image, user: user, is_deleted: true, work_in_progress: false
        )

        get(:index)

        expect(assigns(:src_images).size).to eq(2)
      end

      it 'shows work in progress images' do
        FactoryGirl.create(:src_image, user: user)
        FactoryGirl.create(:src_image, user: user, work_in_progress: false)

        get(:index)

        expect(assigns(:src_images).size).to eq(2)
      end

      it 'shows public images' do
        FactoryGirl.create(:src_image, private: true, work_in_progress: false)
        3.times { FactoryGirl.create(:src_image, work_in_progress: false) }

        get(:index)

        expect(assigns(:src_images).size).to eq(4)
      end
    end

    context 'searching' do
      it 'filters the result by the query string' do
        FactoryGirl.create(
          :src_image,
          user: user,
          name: 'the quick brown fox',
          work_in_progress: false
        )
        si2 = FactoryGirl.create(
          :src_image,
          user: user,
          name: 'the quick red fox',
          work_in_progress: false
        )
        FactoryGirl.create(
          :src_image,
          user: user,
          name: 'the quick black fox',
          work_in_progress: false
        )

        get(:index, params: { q: 'red' })
        expect(assigns(:src_images)).to eq([si2])
      end

      it 'is case insensitive' do
        si = FactoryGirl.create(
          :src_image,
          user: user,
          name: 'the quick brown fox',
          work_in_progress: false
        )

        get(:index, params: { q: 'QuIcK' })
        expect(assigns(:src_images)).to eq([si])
      end

      it 'ignores leading whitespace' do
        si = FactoryGirl.create(
          :src_image,
          user: user,
          name: 'the quick brown fox',
          work_in_progress: false
        )
        get(:index, params: { q: " \t\r\nquick" })
        expect(assigns(:src_images)).to eq([si])
      end

      it 'ignores trailing whitespace' do
        si = FactoryGirl.create(
          :src_image,
          user: user,
          name: 'the quick brown fox',
          work_in_progress: false
        )
        get(:index, params: { q: "quick \t\n\r" })
        expect(assigns(:src_images)).to eq([si])
      end
    end

    context 'when JSON is requested' do
      it 'serves JSON' do
        src_image1 = FactoryGirl.create(
          :src_image,
          name: 'image 1',
          work_in_progress: false
        )
        src_image1.set_derived_image_fields
        src_image1.save!
        # src images are sorted by most used, create gend images so
        # there is a well-defined sort order for the spec
        2.times { FactoryGirl.create(:gend_image, src_image: src_image1) }

        src_image2 = FactoryGirl.create(
          :src_image,
          name: 'image 1',
          work_in_progress: false
        )
        src_image2.set_derived_image_fields
        src_image2.save!
        1.times { FactoryGirl.create(:gend_image, src_image: src_image2) }

        get :index, format: :json
        parsed_body = JSON.parse(response.body)
        expect(parsed_body[0]).to include(
          'id_hash' => src_image1.id_hash,
          'width' => 399,
          'height' => 399,
          'size' => 9141,
          'content_type' => 'image/jpeg',
          'name' => 'image 1',
          'image_url' =>
               "http://test.host/src_images/#{src_image1.id_hash}.jpg"
        )
        expect(Time.parse(parsed_body[0]['created_at']).to_i).to eq(
          src_image1.created_at.to_i
        )
        expect(Time.parse(parsed_body[0]['updated_at']).to_i).to eq(
          src_image1.updated_at.to_i
        )

        expect(parsed_body[1]).to include(
          'id_hash' => src_image2.id_hash,
          'width' => 399,
          'height' => 399,
          'size' => 9141,
          'content_type' => 'image/jpeg',
          'name' => 'image 1',
          'image_url' =>
              "http://test.host/src_images/#{src_image2.id_hash}.jpg"
        )
        expect(Time.parse(parsed_body[1]['created_at']).to_i).to eq(
          src_image2.created_at.to_i
        )
        expect(Time.parse(parsed_body[1]['updated_at']).to_i).to eq(
          src_image2.updated_at.to_i
        )
      end

      context 'when a gend image host is set in the config' do
        before do
          stub_const('MemeCaptainWeb::Config::GEND_IMAGE_HOST',
                     'gendimagehost.com')
        end

        it 'uses the gend image host in src image urls' do
          src_image1 = FactoryGirl.create(
            :src_image,
            name: 'image 1',
            work_in_progress: false
          )
          src_image1.set_derived_image_fields
          src_image1.save!

          get :index, format: :json
          parsed_body = JSON.parse(response.body)
          expect(parsed_body[0]).to include(
            'id_hash' => src_image1.id_hash,
            'width' => 399,
            'height' => 399,
            'size' => 9141,
            'content_type' => 'image/jpeg',
            'name' => 'image 1',
            'image_url' =>
  "http://gendimagehost.com/src_images/#{src_image1.id_hash}.jpg"
          )
          expect(Time.parse(parsed_body[0]['created_at']).to_i).to eq(
            src_image1.created_at.to_i
          )
          expect(Time.parse(parsed_body[0]['updated_at']).to_i).to eq(
            src_image1.updated_at.to_i
          )
        end
      end
    end
  end

  describe "POST 'create'" do
    let(:image) { fixture_file_upload('/files/ti_duck.jpg', 'image/jpeg') }

    context 'with valid attributes' do
      it 'saves the new source image to the database' do
        expect do
          post(:create, params: { src_image: { image: image } })
        end.to change { SrcImage.count }.by(1)
      end

      it 'increments the src_image.upload statsd counter' do
        expect do
          post(:create, params: { src_image: { image: image } })
        end.to trigger_statsd_increment('src_image.upload')
      end

      it 'sets the creator_ip to the remote ip address' do
        post(:create, params: { src_image: { image: image } })
        expect(SrcImage.last.creator_ip).to eq('0.0.0.0')
      end

      context 'when the request has a CloudFlare IP header' do
        before { request.headers['CF-Connecting-IP'] = '6.6.2.2' }

        it 'sets the creator_ip to the value of CF-Connecting-IP' do
          post(:create, params: { src_image: { image: image } })
          expect(SrcImage.last.creator_ip).to eq('6.6.2.2')
        end
      end

      context 'when the image is loaded from a url' do
        it 'does not increment the src_image.upload statsd counter' do
          expect do
            post(:create, params: {
                   src_image: { url: 'http://images.com/image.jpg' }
                 })
          end.not_to trigger_statsd_increment('src_image.upload')
        end
      end

      context 'when the user requests html' do
        it 'redirects to the index page' do
          post(:create, params: { src_image: { image: image } })

          expect(response).to redirect_to controller: :my, action: :show
        end

        it 'informs the user of success with flash' do
          post(:create, params: { src_image: { image: image } })

          expect(flash[:notice]).to eq('Source image created.')
        end
      end

      context 'when the user requests json' do
        before { request.accept = 'application/json' }

        it 'returns accepted' do
          post(:create, params: {
                 src_image: { url: 'http://test.com/image.jpg' }
               })
          expect(response).to have_http_status(:accepted)
        end

        it 'returns json with id' do
          post(:create, params: {
                 src_image: { url: 'http://test.com/image.jpg' }
               })
          expect(JSON.parse(response.body)['id']).to eq(
            assigns(:src_image).id_hash
          )
        end

        it 'sets the Location header to the pending src image url' do
          post(:create, params: {
                 src_image: { url: 'http://test.com/image.jpg' }
               })
          expect(response.headers['Location']).to eq(
            'http://test.host/pending_src_images/' \
            "#{assigns(:src_image).id_hash}"
          )
        end

        it 'returns the status url in the response' do
          post(:create, params: {
                 src_image: { url: 'http://test.com/image.jpg' }
               })

          expect(JSON.parse(response.body)['status_url']).to eq(
            'http://test.host/pending_src_images/' \
            "#{assigns(:src_image).id_hash}"
          )
        end
      end
    end

    context 'with invalid attributes' do
      it 'does not save the new source image in the database' do
        expect do
          post(:create, params: { src_image: { name: 'test' } })
        end.to_not change { SrcImage.count }
      end

      it 're-renders the new template' do
        post(:create, params: { src_image: { name: 'test' } })

        expect(response).to render_template('new')
      end
    end

    context 'when the user it not logged in' do
      let(:user) { nil }

      it 'saves the new source image to the database' do
        expect do
          post(:create, params: { src_image: { image: image } })
        end.to change { SrcImage.count }.by(1)
      end
    end

    context 'setting an optional name' do
      it 'saves the name to the database' do
        post(:create, params: {
               src_image: { image: image, name: 'a test name' }
             })
        expect(SrcImage.last.name).to eq('a test name')
      end
    end
  end

  describe "PUT 'update'" do
    context 'when owned by the current user' do
      let(:src_image) do
        FactoryGirl.create(:src_image, name: 'pre', user: user)
      end

      it 'updates the name' do
        request.accept = 'application/json'
        put(:update, params: {
              id: src_image.id_hash, src_image: { name: 'test' }
            })

        expect(SrcImage.find_by(id_hash: src_image.id_hash).name).to eq('test')
      end
    end

    context 'when not owned by the current user' do
      let(:src_image) do
        FactoryGirl.create(:src_image, name: 'pre', user: user2)
      end

      it 'does not change the name' do
        request.accept = 'application/json'
        put(:update, params: {
              id: src_image.id_hash, src_image: { name: 'test' }
            })

        expect(SrcImage.find_by(id_hash: src_image.id_hash).name).to eq('pre')
      end
    end
  end

  describe "GET 'show'" do
    context 'when the id is found' do
      let(:src_image) do
        src_image = FactoryGirl.create(:src_image, work_in_progress: false)
        src_image.set_derived_image_fields
        src_image.save!
        src_image
      end

      it 'shows the source image' do
        get(:show, params: { id: src_image.id_hash })

        expect(response).to be_success
      end

      it 'has the right content type' do
        get(:show, params: { id: src_image.id_hash })

        expect(response.headers['Content-Type']).to eq(src_image.content_type)
      end

      it 'has the right Content-Length header' do
        get(:show, params: { id: src_image.id_hash })

        expect(response.headers['Content-Length']).to eq(9141)
      end

      it 'has the right content' do
        get(:show, params: { id: src_image.id_hash })

        expect(response.body).to eq(src_image.image)
      end

      it 'has the correct Cache-Control headers' do
        get(:show, params: { id: src_image.id_hash })

        expect(response.headers['Cache-Control']).to eq(
          'max-age=31557600, public'
        )
      end

      it 'has the correct Expires header' do
        stop_time(Time.parse('feb 8 2010 21:55:00 UTC'))
        get(:show, params: { id: src_image.id_hash })

        expires_header = response.headers['Expires']
        expect(expires_header).to eq('Tue, 08 Feb 2011 21:55:00 GMT')
      end
    end

    context 'when the id is not found' do
      it 'raises record not found' do
        expect do
          get(:show, params: { id: 'does not exist' })
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the source image has been deleted' do
      let(:src_image) do
        FactoryGirl.create(
          :src_image,
          work_in_progress: false,
          is_deleted: true
        )
      end

      it 'raises record not found' do
        expect do
          get(:show, params: { id: src_image.id_hash })
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "DELETE 'destroy'" do
    context 'when the id is found' do
      it 'marks the record as deleted in the database' do
        post(:create, params: { src_image: {
               image: fixture_file_upload('/files/ti_duck.jpg', 'image/jpeg')
             } })
        delete(:destroy, params: { id: assigns(:src_image).id_hash })

        expect(SrcImage.find_by(
          id_hash: assigns(:src_image).id_hash
        ).is_deleted?).to eq(true)
      end

      it 'returns success' do
        post(:create, params: { src_image: {
               image: fixture_file_upload('/files/ti_duck.jpg', 'image/jpeg')
             } })
        delete(:destroy, params: { id: assigns(:src_image).id_hash })

        expect(response).to be_success
      end
    end

    context 'when the id is not found' do
      it 'raises record not found' do
        expect do
          delete(:destroy, params: { id: 'abc' })
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the image is owned by another user' do
      it "doesn't allow it to be deleted" do
        src_image = FactoryGirl.create(:src_image, user: user2)

        delete(:destroy, params: { id: src_image.id_hash })

        expect(response).to be_forbidden
      end
    end
  end
end
