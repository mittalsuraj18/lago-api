# frozen_string_literal: true

module Api
  module V1
    class CustomersController < Api::BaseController
      def create
        service = ::Customers::CreateService.new
        result = service.create_from_api(
          organization: current_organization,
          params: create_params,
        )

        if result.success?
          render(
            json: ::V1::CustomerSerializer.new(
              result.customer,
              root_name: 'customer',
            ),
          )
        else
          render_error_response(result)
        end
      end

      def custom_usage
        customer_id = params[:customer_external_id]
        customer = current_organization.customers.find_by(external_id: customer_id)
        return not_found_error(resource: 'customer') unless customer
        from_datetime = DateTime.parse(params[:from_datetime])
        to_datetime = DateTime.parse(params[:to_datetime])
        # subscriptions = customer.active_subscriptions
        subscriptions = customer.active_and_terminated_subscriptions(from_datetime, to_datetime)
        result = {
          "customer": {
            "name": customer.name,
            "id": customer.external_id,
            "legal_name": customer.legal_name,
            "legal_number": customer.legal_number,
            "address": customer.address_line1,
            "lago_url": customer.logo_url,
            "from_datetime": from_datetime.to_s,
            "to_datetime": to_datetime.to_s,
            "subscriptions": []
          }
        }
        subscriptions.each { |sub|
          service = ::Invoices::CustomerUsageService.new(
            nil,
            customer_id: customer_id,
            subscription_id: sub.external_id,
            organization_id: current_organization.id
          )
          date_service = Subscriptions::DatesService.new_instance(
            sub,
            Time.current,
            current_usage: true,
            )
          service.set_boundaries(from_datetime, to_datetime)
          subscription_data = {
            "id": sub.external_id,
            "name": sub.name,
            "current_period_start": date_service.from_datetime.to_s,
            "current_period_end": date_service.to_datetime.to_s,
          }
          subscription_data[:usage] = service.usage.usage
          (result[:subscriptions] ||= []) << subscription_data
        }
        render(json: result)
      end

      def current_usage
        service = ::Invoices::CustomerUsageService
                    .new(
                      nil,
                      customer_id: params[:customer_external_id],
                      subscription_id: params[:external_subscription_id],
                      organization_id: current_organization.id,
                    )
        result = service.usage

        if result.success?
          render(
            json: ::V1::CustomerUsageSerializer.new(
              result.usage,
              root_name: 'customer_usage',
              includes: %i[charges_usage],
            ),
          )
        else
          render_error_response(result)
        end
      end

      def index
        customers = current_organization.customers
                                        .page(params[:page])
                                        .per(params[:per_page] || PER_PAGE)

        render(
          json: ::CollectionSerializer.new(
            customers,
            ::V1::CustomerSerializer,
            collection_name: 'customers',
            meta: pagination_metadata(customers),
          ),
        )
      end

      def show
        customer = current_organization.customers.find_by(external_id: params[:external_id])

        return not_found_error(resource: 'customer') unless customer

        render(
          json: ::V1::CustomerSerializer.new(
            customer,
            root_name: 'customer',
          ),
        )
      end

      def destroy
        customer = current_organization.customers.find_by(external_id: params[:external_id])
        result = ::Customers::DestroyService.call(customer:)

        if result.success?
          render(
            json: ::V1::CustomerSerializer.new(
              result.customer,
              root_name: 'customer',
            ),
          )
        else
          render_error_response(result)
        end
      end

      private

      def create_params
        params.require(:customer).permit(
          :external_id,
          :name,
          :country,
          :address_line1,
          :address_line2,
          :state,
          :zipcode,
          :email,
          :city,
          :url,
          :phone,
          :logo_url,
          :legal_name,
          :legal_number,
          :currency,
          :timezone,
          billing_configuration: [
            :invoice_grace_period,
            :payment_provider,
            :provider_customer_id,
            :sync,
            :sync_with_provider,
            :vat_rate,
            :document_locale,
          ],
        )
      end
    end
  end
end
