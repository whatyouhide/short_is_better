class CorrectUrl < Grape::Validations::Validator
  def validate_param!(attr_name, params)
    url = params[attr_name]

    return if url =~ /\A#{URI::regexp}\z/

    raise Grape::Exceptions::Validation,
      params: [],
      message: %("#{url}" isn't a valid URL)
  end
end
