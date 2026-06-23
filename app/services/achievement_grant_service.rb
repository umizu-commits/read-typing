class AchievementGrantService
  TYPING_CHECKS = %w[
    first_typing
    typing_10 typing_100 typing_1000
    chars_10000 chars_100000
    time_1hour time_10hours
    cpm_100 cpm_200 cpm_300
    accuracy_100
    streak_3 streak_7 streak_30
  ].freeze

  def initialize(user)
    @user = user
    @granted_keys = user.user_achievements.pluck(:achievement_key).to_set
  end

  def call(context:, typing_result: nil)
    keys = case context
    when :typing_saved  then TYPING_CHECKS
    when :article_saved then %w[first_article]
    when :sns_shared    then %w[sns_share]
    else []
    end

    keys.filter_map do |key|
      next if @granted_keys.include?(key)
      next unless condition_met?(key, typing_result)
      grant!(key)
      key
    end
  end

  private

  def condition_met?(key, result)
    case key
    when "first_typing"  then true
    when "first_article" then @user.articles.count >= 1
    when "typing_10"     then typing_count >= 10
    when "typing_100"    then typing_count >= 100
    when "typing_1000"   then typing_count >= 1000
    when "chars_10000"   then total_chars >= 10_000
    when "chars_100000"  then total_chars >= 100_000
    when "time_1hour"    then total_time >= 3_600
    when "time_10hours"  then total_time >= 36_000
    when "cpm_100"       then result&.cpm.to_f >= 100
    when "cpm_200"       then result&.cpm.to_f >= 200
    when "cpm_300"       then result&.cpm.to_f >= 300
    when "accuracy_100"  then result&.accuracy.to_f >= 100
    when "streak_3"      then current_streak >= 3
    when "streak_7"      then current_streak >= 7
    when "streak_30"     then current_streak >= 30
    when "sns_share"     then true
    else false
    end
  end

  def grant!(key)
    @user.user_achievements.create!(achievement_key: key, achieved_at: Time.current)
    @granted_keys.add(key)
  end

  def typing_count
    @typing_count ||= @user.typing_results.count
  end

  def total_chars
    @total_chars ||= @user.typing_results.sum(:correct_count)
  end

  def total_time
    @total_time ||= @user.typing_results.sum(:elapsed_time)
  end

  def current_streak
    @current_streak ||= calculate_streak
  end

  def calculate_streak
    dates = @user.typing_results
                 .pluck(:created_at)
                 .map(&:to_date)
                 .uniq
                 .sort
                 .reverse

    return 0 if dates.empty?
    return 0 if dates.first < Date.today - 1.day # 最後の練習日が昨日より前ならストリーク途切れ

    streak = 1
    dates.each_cons(2) do |later, earlier|
      break unless later - earlier == 1
      streak += 1
    end
    streak
  end
end
