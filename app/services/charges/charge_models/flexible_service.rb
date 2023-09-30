module Charges
  module ChargeModels
    class FlexibleService < Charges::ChargeModels::BaseService
      protected

      def ranges
        properties['graduated_ranges']&.map(&:with_indifferent_access)
      end

      def select_slab(amount, amount_slabs)
        selected_slab = nil
        amount_slabs.each { |slab|
          if (!slab["from_value"].nil? && !slab["to_value"].nil?) && (slab["from_value"] <= amount && amount <= slab["to_value"])
            selected_slab = slab
            break
          end
          if (!slab["from_value"].nil? && slab["to_value"].nil?) && slab["from_value"] <= amount
            selected_slab = slab
            break
          end
          if (!slab["to_value"].nil? && slab["from_value"].nil?) and amount <= slab["to_value"]
            selected_slab = slab
            break
          end
          if slab["to_value"].nil? and slab["from_value"].nil?
            selected_slab = slab
            break
          end
        }
        selected_slab
      end

      def compute_slab_amount(amount, selected_slab)
        result_amount = 0
        per_unit_amount = BigDecimal((selected_slab[:per_unit_amount] || 0).to_s)
        result_amount += per_unit_amount

        percentage_rate = BigDecimal((selected_slab[:percentage_rate] || 0).to_s)
        percentage_amount = amount * percentage_rate / 100

        per_txn_fixed_fee_deductions = selected_slab[:per_txn_fixed_fee_deductions] || 0
        min_amount = selected_slab[:min_amount]
        max_amount = selected_slab[:max_amount]

        if min_amount and max_amount
          percentage_amount = min(max_amount, max(percentage_amount, min_amount)) - per_txn_fixed_fee_deductions
        elsif min_amount
          percentage_amount = max(percentage_amount, min_amount) - per_txn_fixed_fee_deductions
        elsif max_amount
          percentage_amount = min(max_amount, percentage_amount) - per_txn_fixed_fee_deductions
        else
          percentage_amount = percentage_amount - per_txn_fixed_fee_deductions
        end
        result_amount + percentage_amount
      end

      def compute_per_txn_aggregation
        result_amount = 0
        for range in ranges
          flat_amount = BigDecimal((range[:flat_amount] || 0).to_s)

          amount_slabs = range[:amount_slabs]
          from_value = range[:from_value]
          to_value = range[:to_value]
          unless from_value.nil?
            from_value = from_value == 0 ? 0 : from_value - 1
          end
          amounts_between_volume_range = aggregation_result.events[from_value...to_value]
          is_cumulative_pricing = ActiveModel::Type::Boolean.new.cast(properties['is_cumulative_pricing'] || false)
          if is_cumulative_pricing
            # In cumulative pricing all the data should be part of the range and we should stop iterating pricing
            # ranges when we reach the right range. Otherwise we might charge twice
            amounts_between_volume_range = aggregation_result.events[...to_value] # select till the end of to_value ignoring from_value
            unless amounts_between_volume_range.length() == aggregation_result.events.length()
              next
            end
          end
          # NOTE: Add flat amount to the total
          result_amount += flat_amount unless units.zero?

          unless amounts_between_volume_range.nil?
            amounts_between_volume_range.each { |amount|
              amount = amount.nil? ? 0 : amount
              selected_slab = select_slab(amount, amount_slabs)
              result_amount += compute_slab_amount(amount, selected_slab)
            }
          end
          if is_cumulative_pricing
            # Break once the cumulative pricing is done to avoid duplicate counting
            break
          end
        end
        result_amount
      end

      def compute_amount
        total = 0.0
        total += compute_per_txn_aggregation
        total_take_away_percentage = BigDecimal((properties['total_take_away_percentage'] || 100).to_s)
        # minimum_commitment = BigDecimal((properties['minimum_commitment'] || 0).to_s)
        total = total * total_take_away_percentage / 100
        # max(minimum_commitment, total)
        total
      end

      def max (a, b)
        a > b ? a : b
      end

      def min (a, b)
        a < b ? a : b
      end

    end
  end
end