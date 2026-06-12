class ArticlesController < ApplicationController
  def create
    url = params[:url]
    
    if url.blank?
      redirect_to root_path, alert: "URLを入力してください"
      return
    end

    begin
      uri = URI.parse(url)
      unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
        redirect_to root_path, alert: "正しいURL形式で入力してください（例：https://example.com）"
        return
      end
    rescue URI::InvalidURIError
      redirect_to root_path, alert: "正しいURL形式で入力してください（例：https://example.com）"
      return
    end

    redirect_to root_path, notice: "URLを受け取りました: #{url}"
  end
end