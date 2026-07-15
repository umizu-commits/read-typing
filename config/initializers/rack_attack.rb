ARTICLE_FETCH_PATHS = %w[/articles /articles/fetch].freeze

# 未ログイン
Rack::Attack.throttle("articles/ip", limit: 5, period: 1.hour) do |req|
  if ARTICLE_FETCH_PATHS.include?(req.path) && req.post?
    # ログイン済みの場合は nil を返してカウント対象外にする
    unless req.session["warden.user.user.key"]
      req.env["action_dispatch.remote_ip"].to_s
    end
  end
end

# ログイン
Rack::Attack.throttle("articles/user", limit: 10, period: 1.hour) do |req|
  if ARTICLE_FETCH_PATHS.include?(req.path) && req.post?
    req.session["warden.user.user.key"]&.first&.first
  end
end

# 429レスポンスの設定
Rack::Attack.throttled_responder = lambda do |_req|
  [ 429, { "Content-Type" => "text/plain; charset=utf-8" }, [ "Too Many Requests" ] ]
end
