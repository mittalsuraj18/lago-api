# frozen_string_literal: true

module BillableMetrics
  module Aggregations
    class UniqueCountService < BillableMetrics::Aggregations::BaseService
      def aggregate(from_datetime:, to_datetime:, options: {})
        events = events_scope(from_datetime: from_datetime, to_datetime: to_datetime)
          .where("#{sanitized_field_name} IS NOT NULL")

        result.aggregation = events.count("DISTINCT (#{sanitized_field_name})")
        result.options = options
        result.count = events.count
        result.events = events.pluck(Arel.sql("(#{sanitized_field_name})::numeric"))
        result
      end
    end
  end
end
