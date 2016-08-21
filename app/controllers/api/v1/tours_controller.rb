# encoding: utf-8
# frozen_string_literal: true
module Api
  module V1
    class ToursController < ::Api::BaseController
      def index
        authorize! :index, Tour
        @tours = Tour.where(account_id: current_account.id).order(created_at: :desc)
      end

      def show
        authorize! :read, tour
        @tour = tour
      end

      def create
        @tour ||= Tour.new tour_params
        authorize! :create, @tour
        if @tour.save
          send_realtime_update(@tour)
          render status: :created
        else
          Rails.logger.info "Tour Create Failed: #{@tour.errors.full_messages.to_yaml}"
          render json: ValidationError.new("tour.create", @tour.errors), status: :bad_request
        end
      end

      def update
        @tour = Tour.find_by(id: params[:id], account_id: current_account.id)
        authorize! :update, @tour
        unless @tour.update(tour_params)
          Rails.logger.info "Tour Update Failed: #{@tour.errors.full_messages.to_yaml}"
          render json: ValidationError.new("tour.update", @tour.errors), status: :bad_request
        end
        send_realtime_update(@tour)
      end

      def destroy
        @tour = Tour.find_by(id: params[:id], account_id: current_account.id)
        authorize! :destroy, @tour
        unless @tour.destroy
          Rails.logger.info "Tour Destroy Failed: #{@tour.errors.full_messages.to_yaml}"
          render json: ValidationError.new("tour.destroy", @tour.errors), status: :bad_request
        end
        send_realtime_update(@tour)
      end

      private def tour
        @tour ||= Tour.find_by(account_id: current_account.id, id: params[:id])
      end

      private def send_realtime_update(tour)
        ActionCable.server.broadcast "tours_#{current_user.id}", tour.to_builder.target!
      end

      private def tour_params
        @tour_params ||= params.permit(
          :description, :vessel_id,
          waypoints_attributes: [:milage, :driver_id, :location, :latitude, :longitude]
        ).merge(account_id: current_account.id)
      end
    end
  end
end
