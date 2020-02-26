ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection(:development)

class User < ActiveRecord::Base
  # has_many :bookownermap
  # has_many :historie
  # has_many :tag
end

class Book < ActiveRecord::Base
  # has_many :bookownermap
  # has_many :authoermap
  # has_many :tagmap
  # has_many :historie
end

class Authoermap < ActiveRecord::Base
  belongs_to :book
end

class History < ActiveRecord::Base
  # belongs_to :book
  # belongs_to :user
end

class Tag < ActiveRecord::Base
  # has_many :tagmap
  # belongs_to :user
end

class Tagmap < ActiveRecord::Base
  # belongs_to :book
  # belongs_to :tag
end

class Bookownermap < ActiveRecord::Base
  # belongs_to :user
  # belongs_to :book
end
