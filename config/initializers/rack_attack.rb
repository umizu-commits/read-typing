module ArticleRequestThrottle
  FETCH_PATHS = %w[/articles /articles/fetch].freeze

  module_function

  def target_request?(request)
    request.post? && FETCH_PATHS.include?(request.path)
  end

  def user_id(request)
    # Devise が Warden セッションに保存するシリアライズ済みユーザーIDを読み取る。
    request.session.dig("warden.user.user.key", 0, 0)
  end
end

# 未ログイン
Rack::Attack.throttle("articles/ip", limit: 5, period: 1.hour) do |req|
  next unless ArticleRequestThrottle.target_request?(req)
  next if ArticleRequestThrottle.user_id(req)

  req.env["action_dispatch.remote_ip"].to_s
end

# ログイン
Rack::Attack.throttle("articles/user", limit: 10, period: 1.hour) do |req|
  next unless ArticleRequestThrottle.target_request?(req)

  ArticleRequestThrottle.user_id(req)
end

# 429レスポンスの設定
Rack::Attack.throttled_responder = lambda do |_req|
  [ 429, { "Content-Type" => "text/plain; charset=utf-8" }, [ "Too Many Requests" ] ]
end
