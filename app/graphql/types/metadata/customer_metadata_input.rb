# frozen_string_literal: true

module Types
  module Metadata
    class CustomerMetadataInput < Types::BaseInputObject
      graphql_name 'CustomerMetadataInput'

      argument :key, String, required: true
      argument :value, String, required: true
      argument :display_in_invoice, Boolean, required: false
    end
  end
end