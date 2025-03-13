module Leihs
  module Fields
    def self.load
      YAML.load(IO.read(
        Pathname.new(__FILE__).dirname.join("fields.yml")
      ))
    end
  end
end
