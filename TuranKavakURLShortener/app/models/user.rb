# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  email      :string           not null
#  premium    :boolean          default(FALSE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class User < ApplicationRecord
  validates :email, uniqueness: true, presence: true

  has_many :submitted_urls,
    class_name: :ShortenedUrl,
    foreign_key: :submitter_id,
    primary_key: :id
  
  has_many :visits,
    class_name: :Visit,
    foreign_key: :user_id,
    primary_key: :id
  
  has_many :visited_urls,
    # -> { distinct },
    through: :visits,
    source: :shortened_url

end