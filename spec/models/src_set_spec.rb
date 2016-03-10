# encoding: UTF-8

require 'rails_helper'

describe SrcSet do
  it { should validate_presence_of :name }

  it { should belong_to :user }
  it { should have_and_belong_to_many :src_images }

  let(:set1) { FactoryGirl.create(:src_set) }

  context "determining the set's thumbnail" do
    it 'uses the most used image as the thumbnail for the set' do
      si1 = FactoryGirl.create(:finished_src_image, gend_images_count: 3)
      si2 = FactoryGirl.create(:finished_src_image, gend_images_count: 2)
      si3 = FactoryGirl.create(:finished_src_image, gend_images_count: 1)

      set1.src_images << si1
      set1.src_images << si2
      set1.src_images << si3

      expect(set1.thumbnail).to eq si1.src_thumb
      expect(set1.thumb_width).to eq(si1.src_thumb.width)
      expect(set1.thumb_height).to eq(si1.src_thumb.height)
    end

    context 'when the set is empty' do
      subject(:src_set) { FactoryGirl.create(:src_set) }

      specify { expect(src_set.thumbnail).to eq(nil) }
      specify { expect(src_set.thumb_width).to eq(nil) }
      specify { expect(src_set.thumb_height).to eq(nil) }
    end

    context 'when all images in the set are deleted' do
      it 'returns nil' do
        src_set = FactoryGirl.create(:src_set)
        src_set.src_images << FactoryGirl.create(:src_image, is_deleted: true)
        src_set.src_images << FactoryGirl.create(:src_image, is_deleted: true)

        expect(src_set.thumbnail).to be_nil
      end
    end

    context 'when some images in the set are in progress' do
      it 'ignores the in progress images' do
        src_set = FactoryGirl.create(:src_set)
        src_set.src_images << FactoryGirl.create(
          :src_image, work_in_progress: true)
        si = FactoryGirl.create(:finished_src_image)
        src_set.src_images << si

        expect(src_set.thumbnail).to eq(si.src_thumb)
      end
    end
  end

  context 'creating a new src set with the same name as an active src set' do
    it 'fails validation' do
      expect { FactoryGirl.create(:src_set, name: set1.name) }.to(
        raise_error(ActiveRecord::RecordInvalid))
    end
  end

  context 'creating a new src set with the same name as a deleted src set' do
    it 'allows the src set to be created' do
      set1.is_deleted = true
      set1.save!
      FactoryGirl.create(:src_set, name: set1.name)
    end
  end

  describe '.name_matches' do
    it 'matches at the beginning' do
      src_set1 = FactoryGirl.create(:src_set, name: 'test')
      FactoryGirl.create(:src_set, name: 'no match')
      expect(SrcSet.name_matches('test')).to eq([src_set1])
    end

    it 'matches in the middle' do
      src_set1 = FactoryGirl.create(:src_set, name: 'this is a test!')
      FactoryGirl.create(:src_set, name: 'no match')
      expect(SrcSet.name_matches('test')).to eq([src_set1])
    end

    it 'matches at the end' do
      src_set1 = FactoryGirl.create(:src_set, name: 'this is a test')
      FactoryGirl.create(:src_set, name: 'no match')
      expect(SrcSet.name_matches('test')).to eq([src_set1])
    end

    it 'matches case insensitive' do
      src_set1 = FactoryGirl.create(:src_set, name: 'TeSt')
      FactoryGirl.create(:src_set, name: 'no match')
      expect(SrcSet.name_matches('test')).to eq([src_set1])
    end
  end
end
