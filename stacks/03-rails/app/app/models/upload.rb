# One row in RDS Postgres, one object in S3. The whole stack in a model.
class Upload < ApplicationRecord
  has_one_attached :file

  validates :file, presence: true
end
