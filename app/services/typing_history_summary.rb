class TypingHistorySummary
  PERIODS = %w[7d 30d all].freeze
  CHART_LIMIT = 100

  attr_reader :current_period

  def initialize(typing_results:, period:, now: Time.current, today: Date.current)
    @typing_results = typing_results
    @current_period = period.presence_in(PERIODS) || "30d"
    @now = now
    @today = today
  end

  def any_results?
    @typing_results.exists?
  end

  def latest_result
    recent_results.first
  end

  def previous_result
    recent_results.second
  end

  def cpm_difference
    return unless latest_result && previous_result

    latest_result.cpm - previous_result.cpm
  end

  def accuracy_difference
    return unless latest_result && previous_result

    latest_result.accuracy - previous_result.accuracy
  end

  def total_correct_count
    @total_correct_count ||= @typing_results.sum(:correct_count)
  end

  def total_elapsed_time
    @total_elapsed_time ||= @typing_results.sum(:elapsed_time)
  end

  def total_sessions
    @total_sessions ||= @typing_results.count
  end

  def average_miss_count
    @average_miss_count ||= @typing_results.average(:miss_count).to_f.round(1)
  end

  def chart_data
    @chart_data ||= begin
      results = chart_results
      best_cpm = results.map(&:cpm).max

      results.map do |typing_result|
        title = typing_result.article_title.presence || typing_result.article&.title.presence

        {
          label: typing_result.created_at.strftime("%-m/%-d"),
          full_label: typing_result.created_at.strftime("%Y/%m/%d %H:%M"),
          cpm: typing_result.cpm,
          accuracy: typing_result.accuracy,
          title: title,
          is_best: results.size > 1 && typing_result.cpm == best_cpm
        }
      end
    end
  end

  def heatmap_days
    @heatmap_days ||= begin
      target_start = Date.new(@today.year, 1, 1)
      target_end = Date.new(@today.year, 12, 31)
      padded_start = target_start - target_start.wday
      padded_end = target_end + (6 - target_end.wday)
      daily_counts = typing_results_by_date(target_start)

      (padded_start..padded_end).map do |date|
        in_year = date.between?(target_start, target_end)
        in_range = in_year && date <= @today

        {
          date: date,
          count: in_range ? daily_counts[date] : 0,
          in_range: in_range,
          in_year: in_year
        }
      end
    end
  end

  def heatmap_active_days
    heatmap_days.count { |day| day[:in_range] && day[:count].positive? }
  end

  def heatmap_total_count
    heatmap_days.sum { |day| day[:in_range] ? day[:count] : 0 }
  end

  def year
    @today.year
  end

  private

  def recent_results
    @recent_results ||= @typing_results.order(created_at: :desc).limit(2).to_a
  end

  def chart_results
    @chart_results ||= begin
      scope = @typing_results.order(created_at: :desc)
      scope = scope.where(created_at: (@now - 7.days)..) if current_period == "7d"
      scope = scope.where(created_at: (@now - 30.days)..) if current_period == "30d"

      scope.limit(CHART_LIMIT).includes(:article).to_a.reverse
    end
  end

  def typing_results_by_date(target_start)
    @typing_results
      .where(created_at: target_start.beginning_of_day..@today.end_of_day)
      .pluck(:created_at)
      .each_with_object(Hash.new(0)) do |created_at, counts|
        counts[created_at.to_date] += 1
      end
  end
end
