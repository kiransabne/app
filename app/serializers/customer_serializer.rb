class CustomerSerializer < ActiveModel::Serializer
  attributes :uuid, :name, :created_at, :updated_at

  def uuid
    object.id.to_s
  end
end
