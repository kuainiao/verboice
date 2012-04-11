class Parsers::UserFlowNode::UserCommand

  def self.can_handle? params
    params['type'] == name.downcase[name.rindex('::') + 2 ... name.size]
  end

  def self.for application, params
    (SuitableClassFinder.find_direct_subclass_of self, suitable_for: params).value.new application, params
  end

end