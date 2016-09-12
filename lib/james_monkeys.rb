class Object
  # lets you use  "a".in?(alphabet) instead of alphabet.include?("a")
  # pure syntactic sugar, but we're diabetics over here.
  def in?(*args)
    collection = (args.length == 1 ? args.first : args)
    collection ? collection.include?(self) : false
  end

  def listify(opts = {})
    case self
    when NilClass
      opts[:include_nil] ? [nil] : []
    when Array
      self
    else
      [self]
    end

  end
end

class Hash
  # creates a hash of arbitrary depth: you can refer to nested hashes without initialization.
  def self.arbitrary_depth
    Hash.new(&(p=lambda{|h,k| h[k] = Hash.new(&p)}))
  end
end
