require 'net/http'

class SrcImage < ActiveRecord::Base
  include HasImageConcern
  include IdHashConcern
  include HasPostProcessConcern

  attr_accessible :image, :url, :private

  belongs_to :user
  has_one :src_thumb
  has_many :gend_images
  has_and_belongs_to_many :src_sets

  validate :image_if_not_url

  def image_if_not_url
    if url.blank? && image.blank?
      errors.add :image, 'is required if url is not set.'
    end
  end

  protected

  def self.load_from_url(the_url)
    case the_url
      when %r{\|}
        load_multi_vert the_url
      when %r{\[\]}
        load_multi_horiz the_url
      else
        Net::HTTP.get(URI(the_url))
    end
  end

  def self.load_multi_vert(the_url)
    images = the_url.split('|').map { |u| Magick::ImageList.new.from_blob(load_from_url(u)).first }

    min_width = images.map(&:columns).min

    images.select { |i| i.columns > min_width }.each do |i|
      i.resize_to_fit! min_width
    end

    img_list = Magick::ImageList.new
    img_list.push(*images)

    img_list.append(true).to_blob
  end

  def self.load_multi_horiz(the_url)
    images = the_url.split('[]').map { |u| Magick::ImageList.new.from_blob(load_from_url(u)).first }

    min_height = images.map(&:rows).min

    images.select { |i| i.rows > min_height }.each do |i|
      i.resize_to_fit! nil, min_height
    end

    img_list = Magick::ImageList.new
    img_list.push(*images)

    img_list.append(false).to_blob
  end

  def post_process
    if url
      self.image = self.class.load_from_url(url)
      set_derived_image_fields
    end

    img = magick_image_list

    img.auto_orient!
    img.strip!

    if width > MemeCaptainWeb::Config::SourceImageSide or
        height > MemeCaptainWeb::Config::SourceImageSide
      img.resize_to_fit_anim!(MemeCaptainWeb::Config::SourceImageSide)
    end

    thumb_img = img.resize_to_fill_anim(MemeCaptainWeb::Config::ThumbSide)

    watermark_img = Magick::ImageList.new(Rails.root + 'app/assets/images/watermark.png')
    img.extend MemeCaptain::ImageList::Watermark
    img.watermark_mc watermark_img

    self.image = img.to_blob

    self.src_thumb = SrcThumb.new(:image => thumb_img.to_blob)
  end

  scope :active, where(:is_deleted => false)

  scope :owned_by, lambda { |user| where(:user_id => user.id) }

  scope :most_recent, lambda { |limit=1| order(:updated_at).reverse_order.limit(limit) }

  scope :public, where(private: false)

  scope :name_matches, ->(query) { where('name LIKE ?', "%#{query.downcase}%") if query }

  scope :most_used, lambda { |limit=1| order(:gend_images_count).reverse_order.limit(limit) }

  scope :finished, where(work_in_progress: false)
end
