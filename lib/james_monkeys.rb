class Object
  # lets you use  "a".in?(alphabet) instead of alphabet.include?("a")
  # pure syntactic sugar, but we're diabetics over here.
  def in?(*args)
    collection = (args.length == 1 ? args.first : args)
    collection ? collection.include?(self) : false
  end
end
