class BaseController < ApplicationController
  include NumberHelper
  skip_authorization_check
  before_action :authenticate_user!, only: [:fail]

  def index
    if user_signed_in?
      dashboard
    else
      welcome
    end
  end

  def dashboard
    @charged_invoices = current_account.invoices.order('date DESC').charged
    @paid_invoices = current_account.invoices.order('date DESC').paid.year(Time.now.year)
    @last_invoices = current_account.invoices.order('date DESC').paid.year(Time.now.year - 1)
    @budgets = current_account.projects.with_budget.includes(:tasks).order('tasks.updated_at DESC')
    @timers_chart_data = generate_timers_chart_data
    @invoices_chart_data, @invoices_max_values = generate_invoices_chart_data
    render 'dashboard'
  end

  def welcome
    @active_nav = 'welcome'
    render 'welcome'
  end

  def generate_timers_chart_data
    result = []
    start_date = Date.today - 1.month
    end_date = Date.today
    current_account.projects.each do |project|
      chart = { key: project.name, values: [] }

      next if project.timers.where(date: start_date..end_date).blank?

      (start_date..end_date).each do |date|
        timers = current_account.timers.includes(:task).where(date: date, "tasks.project_id" => project.id).references(:task).all
        value = 0.0
        timers.each do |timer|
          value += timer.value.to_d
        end
        chart[:values] << { x: I18n.l(date, format: :db), y: value.to_f }
      end
      result << chart
    end
    result
  end

  def generate_invoices_chart_data
    result = []

    result, max_values_current = values_for_year(result, Date.today.year)
    max_values_last = []
    if current_account.invoices.where("date < ?", (Date.today - 1.year).end_of_year).count > 0
      result, max_values_last = values_for_year(result, (Date.today - 1.year).year, "last")
    end

    [result, (max_values_current + max_values_last)]
  end

  # TODO: Refactor!!!
  # rubocop:disable Metrics/CyclomaticComplexity
  def values_for_year(result, year)
    sum = { key: I18n.t(:"labels.chart.invoices.sum", year: year), values: [] }
    month = { key: I18n.t(:"labels.chart.invoices.month", year: year), values: [] }

    last_value = 0.0
    max_month_value = 0.0
    (1..12).each do |month_id|
      start_date = Date.parse("#{year}-#{month_id}-1").at_beginning_of_month
      end_date = Date.parse("#{year}-#{month_id}-1").at_end_of_month

      value = 0.0
      current_account.invoices.where(date: start_date..end_date).all.each do |invoice|
        value += invoice.value.to_d
      end

      if value.zero? && end_date > Date.today
        month_value = sum_value = nil
      elsif value.zero? && end_date < Date.today
        month_value = 0.0
        sum_value = last_value
      else
        month_value = value
        last_value = sum_value = (last_value + value.to_f)
      end

      start_date += 1.year if start_date.year != Date.today.year

      month[:values] << [(start_date.to_time.to_i * 1000), month_value]
      sum[:values] << [(start_date.to_time.to_i * 1000), sum_value]

      max_month_value = value.to_f if max_month_value < value.to_f
    end
    max_values = [round_to_k(last_value), round_to_k(max_month_value)]

    result << sum
    result << month
    [result, max_values]
  end
end
