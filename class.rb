# frozen_string_literal: true

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection(:development)

class User < ActiveRecord::Base
  has_many :bookownermaps
  has_many :books, through: :bookownermaps

  # has_many :histories
end

class Bookownermap < ActiveRecord::Base
  belongs_to :user
  belongs_to :book
end

class Book < ActiveRecord::Base
  has_many :bookownermaps
  has_many :users, through: :bookownermaps

  has_many :tagmaps
  has_many :tags, through: :tagmaps

  has_many :histories
  has_many :statuses, through: :histories
end

class Tagmap < ActiveRecord::Base
  belongs_to :book
  belongs_to :tag
end

class Tag < ActiveRecord::Base
  has_many :tagmaps
  has_many :books, through: :tagmaps
  belongs_to :user
end

class Authoermap < ActiveRecord::Base
  belongs_to :book
end

class History < ActiveRecord::Base
  belongs_to :book
  belongs_to :status
end

class Status < ActiveRecord::Base
  has_many :histories
  has_many :books, through: :histories
end
