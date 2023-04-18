# frozen_string_literal: true

module BillableMetrics
  module Aggregations
    class CountService < BillableMetrics::Aggregations::BaseService
      def aggregate(from_datetime:, to_datetime:, options: {})
        events = events_scope(from_datetime: from_datetime, to_datetime: to_datetime)
        result.aggregation = events.count
        result.count = result.aggregation
        result.options = options
        result.events = events.pluck(Arel.sql("(#{sanitized_field_name})::numeric"))
        result
      end
    end
  end
end
